import { Router } from 'express';
import { z } from 'zod';
import { authenticate } from '../../middleware/auth.middleware.js';
import { PaymentService } from './payment.service.js';
import { VaultModel } from '../vault/vault.model.js';
import { AppError } from '../../errors/AppError.js';

const router = Router();
const paymentService = new PaymentService();

const initiateSchema = z.object({
  vaultId: z.string().min(1),
  psp: z.enum(['esewa', 'khalti']),
});

// ── POST /payment/initiate — Unified initiation endpoint ──────────────────
// This is the single endpoint the mobile app calls.
// It delegates to the existing PSP-specific payment service methods.
router.post('/initiate', authenticate, async (req, res, next) => {
  try {
    const { vaultId, psp } = initiateSchema.parse(req.body);
    const userId = (req as any).user.sub;

    const vault = await VaultModel.findById(vaultId).lean();
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    if (vault.buyerId.toString() !== userId) {
      throw new AppError('Only the buyer can fund this vault', 403, 'FORBIDDEN');
    }
    if (vault.state !== 'INITIATED') {
      throw new AppError('Vault is not in a fundable state', 422, 'INVALID_STATE');
    }

    let data: { checkoutUrl: string; [key: string]: any };

    if (psp === 'esewa') {
      data = await paymentService.initiateEsewa(vaultId, vault.amount);
    } else {
      data = await paymentService.initiateKhalti(vaultId, vault.amount, {
        name: 'NepalTrust User',
        phone: (vault as any).buyerPhone ?? '',
      });
    }

    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
});

export default router;
