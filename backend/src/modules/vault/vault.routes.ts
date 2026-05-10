import { Router } from 'express';
import { z } from 'zod';
import { VaultService } from './vault.service.js';
import { VaultModel, VaultState } from './vault.model.js';
import { MessageModel } from './message.model.js';
import { UserModel } from '../user/user.model.js';
import { authenticate } from '../../middleware/auth.middleware.js';
import { AppError } from '../../errors/AppError.js';
import { PDFService } from '../../services/pdf.service.js';

const router = Router();
const vaultService = new VaultService();

// ── Schemas ────────────────────────────────────────────────────────────────
const createVaultSchema = z.object({
  title: z.string().min(3).max(200),
  description: z.string().max(2000).optional(),
  category: z.string().max(100).optional(),
  amount: z.number().positive().max(10_000_000),
  sellerPhone: z.string().regex(/^9[678]\d{8}$/, 'Invalid Nepal phone number'),
  sellerName: z.string().min(3).optional(),
  sellerBank: z.string().min(5).optional(),
  currency: z.literal('NPR').default('NPR'),
});

const shipSchema = z.object({
  trackingNumber: z.string().min(4).max(100).optional(),
  courierCode: z.string().min(2).max(50).optional(),
});

const deliverSchema = z.object({
  qrToken: z.string().min(64).max(64).optional(),
});

// ── POST /vaults — Create ──────────────────────────────────────────────────
router.post('/', authenticate, async (req, res, next) => {
  try {
    const body = createVaultSchema.parse(req.body);
    const actorId = (req as any).user.sub;
    const vault = await vaultService.createVault(body, actorId);
    res.status(201).json({ success: true, data: vault });
  } catch (error) {
    next(error);
  }
});

// ── GET /vaults — List with filters & pagination ───────────────────────────
router.get('/', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    const roleQuery = req.query.role as string | undefined;
    const status = req.query.status as string | undefined;
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(50, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;

    let filter: any;
    if (roleQuery === 'seller') {
      filter = { sellerId: userId };
    } else if (roleQuery === 'buyer') {
      filter = { buyerId: userId };
    } else {
      filter = { $or: [{ buyerId: userId }, { sellerId: userId }] };
    }

    if (status) filter.state = status;

    const [vaults, total] = await Promise.all([
      VaultModel.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      VaultModel.countDocuments(filter),
    ]);

    // Inject role field for frontend filtering
    const mappedVaults = vaults.map(v => ({
      ...v,
      role: v.buyerId.toString() === userId ? 'buyer' : 'seller'
    }));

    res.json({
      success: true,
      data: mappedVaults,
      meta: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
});

// ── GET /vaults/:id — Detail ───────────────────────────────────────────────
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    const vault = await VaultModel.findById(req.params.id)
      .populate('buyerId', 'phone')
      .populate('sellerId', 'phone')
      .lean();
      
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');

    // Only buyer, seller, or admin may read
    const isBuyer = vault.buyerId._id.toString() === userId;
    const isSeller = vault.sellerId._id.toString() === userId;
    if (!isBuyer && !isSeller) {
      throw new AppError('Forbidden', 403, 'FORBIDDEN');
    }

    // Map to simple fields for frontend consumption
    const enrichedVault = {
      ...vault,
      buyerPhone: (vault.buyerId as any).phone,
      sellerPhone: (vault.sellerId as any).phone,
    };

    res.json({ success: true, data: enrichedVault });
  } catch (error) {
    next(error);
  }
});

// ── POST /vaults/:id/ship — Seller marks shipped ───────────────────────────
router.post('/:id/ship', authenticate, async (req, res, next) => {
  try {
    const parsed = shipSchema.parse(req.body);
    const actorId = (req as any).user.sub;

    const vault = await VaultModel.findById(req.params.id);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    if (vault.sellerId.toString() !== actorId) throw new AppError('Only the seller can mark as shipped', 403, 'FORBIDDEN');
    if (vault.state !== VaultState.FUNDED) throw new AppError('Vault must be FUNDED to ship', 422, 'INVALID_TRANSITION');

    // Persist tracking info if provided
    if (parsed.trackingNumber) vault.trackingNumber = parsed.trackingNumber;
    if (parsed.courierCode) vault.courierCode = parsed.courierCode;
    await vault.save();

    const updated = await vaultService.transition(req.params.id!, 'ship', actorId, 'SELLER', parsed);
    res.json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
});

// ── POST /vaults/:id/deliver — Buyer confirms delivery ─────────────────────
router.post('/:id/deliver', authenticate, async (req, res, next) => {
  try {
    const parsed = deliverSchema.parse(req.body);
    const actorId = (req as any).user.sub;

    // If QR token provided, use the secure QR validation flow
    if (parsed.qrToken) {
      const updated = await vaultService.validateDeliveryQR(req.params.id!, parsed.qrToken, actorId);
      return res.json({ success: true, data: updated });
    }

    // Otherwise, direct confirmation (buyer quick-action)
    const vault = await VaultModel.findById(req.params.id);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    if (vault.buyerId.toString() !== actorId) throw new AppError('Only the buyer can confirm delivery', 403, 'FORBIDDEN');
    if (vault.state !== VaultState.SHIPPED) throw new AppError('Vault must be SHIPPED to deliver', 422, 'INVALID_TRANSITION');

    const updated = await vaultService.transition(req.params.id!, 'deliver', actorId, 'BUYER');
    res.json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
});

// ── POST /vaults/:id/confirm — Buyer confirms receipt ─────────────────────
router.post('/:id/confirm', authenticate, async (req, res, next) => {
  try {
    const actorId = (req as any).user.sub;
    const vault = await VaultModel.findById(req.params.id);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    if (vault.buyerId.toString() !== actorId) throw new AppError('Only the buyer can confirm', 403, 'FORBIDDEN');

    const updated = await vaultService.transition(req.params.id!, 'confirm', actorId, 'BUYER');
    res.json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
});

// ── POST /vaults/:id/cancel — Buyer cancels pre-funded ────────────────────
router.post('/:id/cancel', authenticate, async (req, res, next) => {
  try {
    const actorId = (req as any).user.sub;
    const vault = await VaultModel.findById(req.params.id);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    if (vault.buyerId.toString() !== actorId) throw new AppError('Only the buyer can cancel', 403, 'FORBIDDEN');
    if (vault.state !== VaultState.INITIATED) throw new AppError('Can only cancel before funding', 422, 'INVALID_TRANSITION');

    const updated = await vaultService.transition(req.params.id!, 'cancel', actorId, 'BUYER');
    res.json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
});

// ── POST /vaults/:id/dispute — Raise a dispute ────────────────────────────
router.post('/:id/dispute', authenticate, async (req, res, next) => {
  try {
    const actorId = (req as any).user.sub;
    const { reason, description } = z.object({
      reason: z.string().min(5).max(200),
      description: z.string().min(20).max(5000),
    }).parse(req.body);

    const updated = await vaultService.transition(req.params.id!, 'dispute', actorId, 'USER', { reason, description });
    res.json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
});

// ── GET /vaults/:id/delivery-qr — Generate QR token (buyer) ──────────────
router.get('/:id/delivery-qr', authenticate, async (req, res, next) => {
  try {
    const actorId = (req as any).user.sub;
    const token = await vaultService.generateDeliveryQR(req.params.id!, actorId);
    res.json({ success: true, data: { token } });
  } catch (error) {
    next(error);
  }
});

// ── GET /vaults/:id/messages — Chat history ──────────────────────────────
router.get('/:id/messages', authenticate, async (req, res, next) => {
  try {
    const actorId = (req as any).user.sub;
    const vault = await VaultModel.findById(req.params.id);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    
    if (vault.buyerId.toString() !== actorId && vault.sellerId.toString() !== actorId) {
      throw new AppError('Forbidden', 403, 'FORBIDDEN');
    }

    const messages = await MessageModel.find({ vaultId: req.params.id })
      .sort({ createdAt: 1 })
      .limit(100)
      .lean();
    res.json({ success: true, data: messages });
  } catch (error) {
    next(error);
  }
});

// ── POST /vaults/:id/messages — Send message via REST ────────────────────
router.post('/:id/messages', authenticate, async (req, res, next) => {
  try {
    const actorId = (req as any).user.sub;
    const vault = await VaultModel.findById(req.params.id);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    
    if (vault.buyerId.toString() !== actorId && vault.sellerId.toString() !== actorId) {
      throw new AppError('Forbidden', 403, 'FORBIDDEN');
    }

    const { content } = z.object({ content: z.string().min(1).max(2000) }).parse(req.body);

    const msg = await MessageModel.create({
      vaultId: req.params.id,
      senderId: actorId,
      content,
    });

    res.status(201).json({ success: true, data: msg });
  } catch (error) {
    next(error);
  }
});

// ── GET /vaults/:id/audit — Immutable audit trail ─────────────────────────
router.get('/:id/audit', authenticate, async (req, res, next) => {
  try {
    const actorId = (req as any).user.sub;
    const vault = await VaultModel.findById(req.params.id);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    
    // Only buyer, seller, or admin may read audit logs
    if (vault.buyerId.toString() !== actorId && vault.sellerId.toString() !== actorId) {
      throw new AppError('Forbidden', 403, 'FORBIDDEN');
    }

    const logs = await vaultService.getAuditLogs(req.params.id!);
    res.json({ success: true, data: logs });
  } catch (error) {
    next(error);
  }
});

// ── GET /vaults/:id/receipt — Generate PDF Receipt ──────────────────────
router.get('/:id/receipt', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    const vault = await VaultModel.findById(req.params.id);
    
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    
    // Security check: Only buyer or seller can get the receipt
    if (vault.buyerId.toString() !== userId && vault.sellerId.toString() !== userId) {
      throw new AppError('Access denied', 403, 'ACCESS_DENIED');
    }

    const [buyer, seller] = await Promise.all([
      UserModel.findById(vault.buyerId),
      UserModel.findById(vault.sellerId)
    ]);

    const pdfBuffer = await PDFService.generateVaultReceipt(vault as any, buyer, seller);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename=receipt-${vault._id}.pdf`,
      'Content-Length': pdfBuffer.length,
    });
    
    res.send(pdfBuffer);
  } catch (error) {
    next(error);
  }
});

export default router;
