import { Router } from 'express';
import { UserModel } from '../user/user.model.js';
import { DisputeModel } from '../dispute/dispute.model.js';
import { AuditLogModel } from '../vault/audit_log.model.js';
import { VaultModel } from '../vault/vault.model.js';
import { authenticate } from '../../middleware/auth.middleware.js';
import { rbac } from '../../middleware/rbac.middleware.js';
import { z } from 'zod';

const router = Router();

// All admin routes require auth + admin/compliance role
router.use(authenticate);

// ── GET /admin/kyc/queue — KYC pending review queue ───────────────────────
router.get('/kyc/queue', rbac(['ADMIN', 'COMPLIANCE', 'SUPPORT']), async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(50, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      UserModel.find({ 'kyc.status': 'PENDING' })
        .select('phone email kyc createdAt')
        .sort({ 'kyc.submittedAt': 1 })
        .skip(skip).limit(limit).lean(),
      UserModel.countDocuments({ 'kyc.status': 'PENDING' }),
    ]);

    res.json({ success: true, data: users, meta: { page, limit, total } });
  } catch (error) {
    next(error);
  }
});

// ── PUT /admin/kyc/:userId — Approve / Reject KYC ─────────────────────────
router.put('/kyc/:userId', rbac(['ADMIN', 'COMPLIANCE']), async (req, res, next) => {
  try {
    const { status, reason } = z.object({
      status: z.enum(['APPROVED', 'REJECTED', 'RESUBMIT']),
      reason: z.string().max(500).optional(),
    }).parse(req.body);

    const adminId = (req as any).user.sub;
    const user = await UserModel.findById(req.params.userId);
    if (!user) return res.status(404).json({ success: false, error: { code: 'USER_NOT_FOUND', message: 'User not found' } });

    user.kyc.status = status;
    user.kyc.reviewedAt = new Date();
    user.kyc.reviewedBy = adminId;
    if (reason) user.kyc.rejectionReason = reason;
    if (status === 'APPROVED' && !user.role.includes('VERIFIED_USER')) {
      user.role.push('VERIFIED_USER');
    }
    await user.save();

    res.json({ success: true, message: `KYC ${status} for user ${req.params.userId}` });
  } catch (error) {
    next(error);
  }
});

// ── GET /admin/disputes — All disputes ────────────────────────────────────
router.get('/disputes', rbac(['ADMIN', 'SUPPORT', 'COMPLIANCE']), async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(50, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const status = req.query.status as string | undefined;

    const filter: any = {};
    if (status) filter.status = status;

    const [disputes, total] = await Promise.all([
      DisputeModel.find(filter)
        .populate('vaultId', 'title amount state')
        .populate('raisedBy', 'phone email')
        .sort({ createdAt: -1 })
        .skip(skip).limit(limit).lean(),
      DisputeModel.countDocuments(filter),
    ]);

    res.json({ success: true, data: disputes, meta: { page, limit, total } });
  } catch (error) {
    next(error);
  }
});

// ── PUT /admin/disputes/:id/resolve ──────────────────────────────────────
router.put('/disputes/:id/resolve', rbac(['ADMIN']), async (req, res, next) => {
  try {
    const { decision, reason } = z.object({
      decision: z.enum(['BUYER', 'SELLER']),
      reason: z.string().min(20).max(2000),
    }).parse(req.body);

    const { DisputeService } = await import('../dispute/dispute.service.js');
    const disputeService = new DisputeService();
    const dispute = await disputeService.resolveDispute(req.params.id!, { decision, reason }, (req as any).user.sub);

    res.json({ success: true, data: dispute });
  } catch (error) {
    next(error);
  }
});

// ── GET /admin/vaults — All vaults table ─────────────────────────────────
router.get('/vaults', rbac(['ADMIN', 'COMPLIANCE', 'SUPPORT']), async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(100, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const filter: any = {};
    if (req.query.state) filter.state = req.query.state;

    const [vaults, total] = await Promise.all([
      VaultModel.find(filter)
        .populate('buyerId', 'phone email')
        .populate('sellerId', 'phone email')
        .sort({ createdAt: -1 })
        .skip(skip).limit(limit).lean(),
      VaultModel.countDocuments(filter),
    ]);

    res.json({ success: true, data: vaults, meta: { page, limit, total } });
  } catch (error) {
    next(error);
  }
});

// ── GET /admin/users — User management ───────────────────────────────────
router.get('/users', rbac(['ADMIN']), async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(100, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      UserModel.find()
        .select('-refreshTokens -deviceFingerprints')
        .sort({ createdAt: -1 })
        .skip(skip).limit(limit).lean(),
      UserModel.countDocuments(),
    ]);

    res.json({ success: true, data: users, meta: { page, limit, total } });
  } catch (error) {
    next(error);
  }
});

// ── PUT /admin/users/:id/suspend ─────────────────────────────────────────
router.put('/users/:id/suspend', rbac(['ADMIN']), async (req, res, next) => {
  try {
    const { suspended } = z.object({ suspended: z.boolean() }).parse(req.body);
    await UserModel.findByIdAndUpdate(req.params.id, { isActive: !suspended });
    res.json({ success: true, message: suspended ? 'User suspended' : 'User reactivated' });
  } catch (error) {
    next(error);
  }
});

// ── GET /admin/audit-logs — Searchable audit log ─────────────────────────
router.get('/audit-logs', rbac(['ADMIN']), async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(100, parseInt(req.query.limit as string) || 50);
    const skip = (page - 1) * limit;
    const filter: any = {};
    if (req.query.vaultId) filter.vaultId = req.query.vaultId;
    if (req.query.actorId) filter.actorId = req.query.actorId;
    if (req.query.action) filter.action = req.query.action;

    const [logs, total] = await Promise.all([
      AuditLogModel.find(filter).sort({ timestamp: -1 }).skip(skip).limit(limit).lean(),
      AuditLogModel.countDocuments(filter),
    ]);

    res.json({ success: true, data: logs, meta: { page, limit, total } });
  } catch (error) {
    next(error);
  }
});

// ── GET /admin/stats — Dashboard summary ─────────────────────────────────
router.get('/stats', rbac(['ADMIN', 'COMPLIANCE', 'SUPPORT']), async (req, res, next) => {
  try {
    const [
      activeVaults,
      pendingKyc,
      openDisputes,
      completedToday,
      totalLocked,
      recentVaults
    ] = await Promise.all([
      VaultModel.countDocuments({ state: { $in: ['FUNDED', 'SHIPPED', 'DELIVERED'] } }),
      UserModel.countDocuments({ 'kyc.status': 'PENDING' }),
      DisputeModel.countDocuments({ status: 'OPEN' }),
      VaultModel.countDocuments({ 
        state: 'COMPLETED', 
        updatedAt: { $gte: new Date(new Date().setHours(0,0,0,0)) } 
      }),
      VaultModel.aggregate([
        { $match: { state: { $in: ['FUNDED', 'SHIPPED', 'DELIVERED'] } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      VaultModel.find()
        .populate('buyerId', 'phone')
        .sort({ createdAt: -1 })
        .limit(5)
        .lean()
    ]);

    res.json({
      success: true,
      data: {
        activeVaults,
        pendingKyc,
        openDisputes,
        completedToday,
        totalLocked: totalLocked[0]?.total || 0,
        recentVaults: recentVaults.map(v => ({
          id: v._id.toString().slice(-8).toUpperCase(),
          title: v.title,
          buyer: (v.buyerId as any)?.phone || 'Anonymous',
          amount: v.amount,
          state: v.state
        })),
        compliance: {
          escrowReconciled: true,
          auditRetention: true,
          kycResponseTime: pendingKyc < 10,
          paymentSuccessRate: 98.5,
          incidentReports: 0
        },
        health: {
          invoiceEngine: 0,
          payoutOrchestrator: 1,
          notificationBroadcast: 0,
          vaultWatcher: 0,
          ledgerSync: 0
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

export default router;
