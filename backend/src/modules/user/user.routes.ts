import { Router } from 'express';
import { z } from 'zod';
import { authenticate } from '../../middleware/auth.middleware.js';
import { UserModel } from './user.model.js';
import { AppError } from '../../errors/AppError.js';
import { normalizePhone } from '../../utils/phone.js';

const router = Router();

// ── GET /users/me — Current user profile ──────────────────────────────────
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    const user = await UserModel.findById(userId)
      .select('-refreshTokens -deviceFingerprints')
      .lean();

    if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');

    res.json({
      success: true,
      data: {
        id: user._id,
        phone: user.phone,
        email: user.email,
        name: user.kyc?.fullName ?? '',
        role: user.role,
        language: user.language,
        kycStatus: user.kyc?.status ?? 'NOT_SUBMITTED',
        isActive: user.isActive,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── PATCH /users/me — Update language preference ──────────────────────────
router.patch('/me', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    const { language } = z.object({
      language: z.enum(['en', 'ne']),
    }).parse(req.body);

    await UserModel.findByIdAndUpdate(userId, { language });
    res.json({ success: true, data: { language } });
  } catch (error) {
    next(error);
  }
});

// ── POST /users/me/fcm-token — Register FCM token for Push Notifications ──
router.post('/me/fcm-token', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    const { fcmToken } = z.object({ fcmToken: z.string().min(10) }).parse(req.body);

    await UserModel.findByIdAndUpdate(userId, {
      $addToSet: { fcmTokens: fcmToken } // Prevent duplicate tokens
    });

    res.json({ success: true, message: 'FCM token registered' });
  } catch (error) {
    next(error);
  }
});

// ── GET /users/me/stats — Vault statistics for profile ────────────────────
router.get('/me/stats', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    // Import inline to avoid circular dependency
    const { VaultModel } = await import('../vault/vault.model.js');

    const [asBuyer, asSeller] = await Promise.all([
      VaultModel.countDocuments({ buyerId: userId }),
      VaultModel.countDocuments({ sellerId: userId }),
    ]);

    const completed = await VaultModel.countDocuments({
      $or: [{ buyerId: userId }, { sellerId: userId }],
      state: 'COMPLETED',
    });

    res.json({
      success: true,
      data: { totalAsbuyer: asBuyer, totalAsSeller: asSeller, completed },
    });
  } catch (error) {
    next(error);
  }
});

// ── GET /users/lookup/:phone — Lookup user details for auto-fill ──────────
router.get('/lookup/:phone', authenticate, async (req, res, next) => {
  try {
    const { phone } = req.params;
    const normalizedPhone = normalizePhone(phone);
    const user = await UserModel.findOne({ phone: normalizedPhone }).select('kyc.fullName kyc.status bankDetails');
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ 
      success: true, 
      data: { 
        fullName: user.kyc?.fullName || 'NepalTrust Verified User',
        isVerified: user.kyc?.status === 'APPROVED',
        bankAccount: user.bankDetails?.accountNumber || ''
      } 
    });
  } catch (error) {
    next(error);
  }
});

// ── DELETE /users/me — Account deletion (App Store Compliance) ────────────
router.delete('/me', authenticate, async (req, res, next) => {
  try {
    const userId = (req as any).user.sub;
    
    // Import VaultModel to check for active transactions
    const { VaultModel } = await import('../vault/vault.model.js');
    
    // Prevent deletion if there are active vaults holding funds
    const activeVaults = await VaultModel.countDocuments({
      $or: [{ buyerId: userId }, { sellerId: userId }],
      state: { $in: ['INITIATED', 'FUNDED', 'SHIPPED', 'DELIVERED', 'DISPUTED', 'ADMIN_REVIEW'] }
    });

    if (activeVaults > 0) {
      throw new AppError(
        'Cannot delete account while you have active or pending escrow vaults. Please complete or cancel them first.',
        400,
        'ACTIVE_VAULTS_EXIST'
      );
    }

    // Soft delete or Hard delete based on compliance. Doing Hard Delete for GDPR/App Store.
    await UserModel.findByIdAndDelete(userId);
    
    res.json({ success: true, message: 'Account and personal data successfully deleted.' });
  } catch (error) {
    next(error);
  }
});

export default router;
