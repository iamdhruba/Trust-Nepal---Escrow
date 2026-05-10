import { Router } from 'express';
import crypto from 'crypto';
import { z } from 'zod';
import { PaymentService } from './payment.service.js';
import { VaultService } from '../vault/vault.service.js';
import { authenticate } from '../../middleware/auth.middleware.js';
import { AppError } from '../../errors/AppError.js';

const router = Router();
const paymentService = new PaymentService();
const vaultService = new VaultService();

// ── POST /payments/esewa/initiate ─────────────────────────────────────────
router.post('/esewa/initiate', authenticate, async (req, res, next) => {
  try {
    const { vaultId, amount } = z.object({
      vaultId: z.string(),
      amount: z.number().positive(),
    }).parse(req.body);

    const data = await paymentService.initiateEsewa(vaultId, amount);
    
    // Find the intent we just created to get its ID
    const { PaymentIntentModel } = await import('./payment_intent.model.js');
    const intent = await PaymentIntentModel.findOne({ idempotencyKey: data.sdk_params.productId });
    
    if (intent) {
      data.checkoutUrl = `${process.env.API_BASE_URL}/api/v1/payments/esewa/web-checkout/${intent._id}`;
    }

    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
});

// ── GET /payments/esewa/web-checkout/:intentId ─────────────────────────────
router.get('/esewa/web-checkout/:intentId', async (req, res, next) => {
  try {
    const { intentId } = req.params;
    const html = await paymentService.generateEsewaForm(intentId);
    res.send(html);
  } catch (error) {
    next(error);
  }
});

// ── GET /payments/esewa/callback — eSewa redirects here (success) ─────────
router.get('/esewa/callback', async (req, res, next) => {
  try {
    const { data } = req.query;
    if (typeof data !== 'string') throw new AppError('Invalid callback', 400, 'INVALID_CALLBACK');

    const decoded = JSON.parse(Buffer.from(data, 'base64').toString());
    const eventId = decoded.transaction_uuid;

    // Dedup
    const isNew = await paymentService.recordWebhook('ESEWA', eventId, data, {}, true);
    if (!isNew) {
      return res.redirect(`${process.env.APP_DEEP_LINK || 'http://localhost:5173'}/payment-success`);
    }

    try {
      const { vaultId } = await paymentService.verifyEsewa(data);
      await vaultService.transition(vaultId, 'fund', 'system', 'SYSTEM', { paymentIntentId: decoded.transaction_uuid });
      await paymentService.markWebhookProcessed('ESEWA', eventId);
      res.redirect(`${process.env.APP_DEEP_LINK || 'http://localhost:5173'}/payment-success?vaultId=${vaultId}`);
    } catch (err: any) {
      await paymentService.markWebhookProcessed('ESEWA', eventId, err.message);
      throw err;
    }
  } catch (error) {
    next(error);
  }
});

// ── POST /payments/khalti/initiate ────────────────────────────────────────
router.post('/khalti/initiate', authenticate, async (req, res, next) => {
  try {
    const { vaultId, amount, customerInfo } = z.object({
      vaultId: z.string(),
      amount: z.number().positive(),
      customerInfo: z.object({
        name: z.string(),
        email: z.string().email().optional(),
        phone: z.string(),
      }),
    }).parse(req.body);

    const data = await paymentService.initiateKhalti(vaultId, amount, customerInfo);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
});

// ── GET /payments/khalti/callback — Khalti redirects here ─────────────────
router.get('/khalti/callback', async (req, res, next) => {
  try {
    const { pidx, status } = req.query;
    if (typeof pidx !== 'string') throw new AppError('Invalid callback', 400, 'INVALID_CALLBACK');
    if (status !== 'Completed') {
      return res.redirect(`${process.env.APP_DEEP_LINK || 'http://localhost:5173'}/payment-failed`);
    }

    const isNew = await paymentService.recordWebhook('KHALTI', pidx, JSON.stringify(req.query), {}, true);
    if (!isNew) {
      return res.redirect(`${process.env.APP_DEEP_LINK || 'http://localhost:5173'}/payment-success`);
    }

    try {
      const { vaultId } = await paymentService.verifyKhalti(pidx);
      await vaultService.transition(vaultId, 'fund', 'system', 'SYSTEM', { pidx });
      await paymentService.markWebhookProcessed('KHALTI', pidx);
      res.redirect(`${process.env.APP_DEEP_LINK || 'http://localhost:5173'}/payment-success?vaultId=${vaultId}`);
    } catch (err: any) {
      await paymentService.markWebhookProcessed('KHALTI', pidx, err.message);
      throw err;
    }
  } catch (error) {
    next(error);
  }
});

// ── POST /payments/esewa/failure — eSewa redirects here (failure) ─────────
router.get('/esewa/failure', async (_req, res) => {
  res.redirect(`${process.env.APP_DEEP_LINK || 'http://localhost:5173'}/payment-failed`);
});

export default router;
