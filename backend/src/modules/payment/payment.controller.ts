import { Request, Response, NextFunction } from 'express';
import { PaymentService } from './payment.service.js';
import { VaultService } from '../vault/vault.service.js';
import { z } from 'zod';

const paymentService = new PaymentService();
const vaultService = new VaultService();

export const initiateEsewa = async (req: Request, res: Response, next: NextFunction) => {
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
};

export const esewaCallback = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { data } = req.query;
    if (typeof data !== 'string') throw new Error('Invalid callback data');

    await paymentService.verifyEsewa(data);
    
    // Decoded data to find vaultId and trigger transition
    const decoded = JSON.parse(Buffer.from(data, 'base64').toString());
    const paymentIntent = await (await import('./payment_intent.model.js')).PaymentIntentModel.findOne({ idempotencyKey: decoded.transaction_uuid });
    
    if (paymentIntent) {
      await vaultService.transition(
        paymentIntent.vaultId.toString(),
        'fund',
        'system',
        'SYSTEM',
        { paymentIntentId: paymentIntent._id }
      );
    }

    res.redirect('http://localhost:3000/payment-success'); // Client redirect
  } catch (error) {
    next(error);
  }
};

export const esewaWebCheckout = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { intentId } = req.params;
    const formHtml = await paymentService.generateEsewaForm(intentId);
    res.send(formHtml);
  } catch (error) {
    next(error);
  }
};
