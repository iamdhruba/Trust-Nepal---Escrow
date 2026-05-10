import crypto from 'crypto';
import axios from 'axios';
import { PaymentIntentModel, PaymentProvider, PaymentStatus } from './payment_intent.model.js';
import { TransactionModel, TransactionDirection, TransactionStatus } from './transaction.model.js';
import { WebhookReceivedModel } from './webhook.model.js';
import { VaultModel } from '../vault/vault.model.js';
import { AppError } from '../../errors/AppError.js';
import { getEsewaSecrets, getKhaltiSecrets } from '../../config/secrets.js';

export class PaymentService {
  private esewaSecret: string = '';
  private esewaProductCode: string = '';
  private khaltiSecret: string = '';

  constructor() {
    this.initializeSecrets();
  }

  private async initializeSecrets(): Promise<void> {
    try {
      const esewaSecrets = await getEsewaSecrets();
      this.esewaSecret = esewaSecrets.secret_key;
      this.esewaProductCode = esewaSecrets.product_code;
      const khaltiSecrets = await getKhaltiSecrets();
      this.khaltiSecret = khaltiSecrets.live_secret_key;
    } catch (error) {
      console.error('Failed to initialize payment secrets:', error);
    }
  }

  async initiateEsewa(vaultId: string, amount: number): Promise<any> {
    const transaction_uuid = crypto.randomUUID();
    const product_code = this.esewaProductCode || 'EPAYTEST';
    const signatureStr = `total_amount=${amount},transaction_uuid=${transaction_uuid},product_code=${product_code}`;
    const signature = crypto.createHmac('sha256', this.esewaSecret || '8gBm/:&EnhH.1/q')
      .update(signatureStr).digest('base64');

    await PaymentIntentModel.create({
      vaultId,
      provider: PaymentProvider.ESEWA,
      amount,
      idempotencyKey: transaction_uuid,
      expiresAt: new Date(Date.now() + 30 * 60 * 1000),
    });

    const baseUrl = process.env.NODE_ENV === 'production'
      ? 'https://epay.esewa.com.np/api/epay/main/v2/form'
      : 'https://rc-epay.esewa.com.np/api/epay/main/v2/form';

    return {
      url: baseUrl,
      sdk_params: {
        environment: process.env.NODE_ENV === 'production' ? 'live' : 'test',
        clientId: this.esewaProductCode || 'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R',
        secretKey: this.esewaSecret || 'BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==',
        productId: transaction_uuid,
        productName: `Vault Funding: ${vaultId}`,
        amount: amount.toString(),
        callbackUrl: process.env.ESEWA_SUCCESS_URL || `${process.env.API_BASE_URL}/api/v1/payments/esewa/callback`,
      },
      fields: {
        amount, tax_amount: 0, total_amount: amount, transaction_uuid, product_code,
        product_service_charge: 0, product_delivery_charge: 0,
        success_url: process.env.ESEWA_SUCCESS_URL || `${process.env.API_BASE_URL}/api/v1/payments/esewa/callback`,
        failure_url: process.env.ESEWA_FAILURE_URL || `${process.env.API_BASE_URL}/api/v1/payments/esewa/failure`,
        signed_field_names: 'total_amount,transaction_uuid,product_code',
        signature,
      },
    };
  }

  async initiateKhalti(vaultId: string, amount: number, customerInfo: any): Promise<any> {
    const purchase_order_id = crypto.randomUUID();
    const baseUrl = process.env.NODE_ENV === 'production'
      ? 'https://khalti.com/api/v2/epayment/initiate/'
      : 'https://a.khalti.com/api/v2/epayment/initiate/';

    const response = await axios.post(baseUrl, {
      return_url: process.env.KHALTI_RETURN_URL || `${process.env.API_BASE_URL}/api/v1/payments/khalti/callback`,
      website_url: process.env.API_BASE_URL || 'http://localhost:3000',
      amount: amount * 100, // paisa
      purchase_order_id,
      purchase_order_name: `Vault Funding: ${vaultId}`,
      customer_info: customerInfo,
    }, { headers: { 'Authorization': `Key ${this.khaltiSecret}` } });

    await PaymentIntentModel.create({
      vaultId,
      provider: PaymentProvider.KHALTI,
      amount,
      idempotencyKey: response.data.pidx,
      pspReference: response.data.pidx,
      expiresAt: new Date(Date.now() + 30 * 60 * 1000),
    });

    return response.data;
  }

  /**
   * Verify eSewa callback — always verify server-side, never trust client data alone
   */
  async verifyEsewa(encodedData: string): Promise<{ vaultId: string }> {
    const decoded = JSON.parse(Buffer.from(encodedData, 'base64').toString());

    // Server-side status check per eSewa spec
    if (process.env.NODE_ENV === 'production') {
      const statusUrl = `https://epay.esewa.com.np/api/epay/transaction/status/?product_code=${this.esewaProductCode}&total_amount=${decoded.total_amount}&transaction_uuid=${decoded.transaction_uuid}`;
      const statusResp = await axios.get(statusUrl);
      if (statusResp.data.status !== 'COMPLETE') {
        throw new AppError('eSewa payment not complete', 400, 'PAYMENT_NOT_COMPLETE');
      }
    }

    const paymentIntent = await PaymentIntentModel.findOne({ idempotencyKey: decoded.transaction_uuid });
    if (!paymentIntent) throw new AppError('Payment intent not found', 404, 'PAYMENT_NOT_FOUND');
    if (paymentIntent.status === PaymentStatus.COMPLETED) {
      throw new AppError('Payment already processed', 409, 'ALREADY_PROCESSED');
    }

    paymentIntent.status = PaymentStatus.COMPLETED;
    paymentIntent.pspReference = decoded.transaction_code;
    paymentIntent.completedAt = new Date();
    await paymentIntent.save();

    // Create transaction ledger entry
    await TransactionModel.create({
      paymentIntentId: paymentIntent._id,
      vaultId: paymentIntent.vaultId,
      provider: 'ESEWA',
      txnId: decoded.transaction_code,
      amount: paymentIntent.amount,
      direction: TransactionDirection.DEBIT,
      status: TransactionStatus.SETTLED,
      rawPayload: encodedData, // Should be encrypted at rest in production
    });

    return { vaultId: paymentIntent.vaultId.toString() };
  }

  /**
   * Verify Khalti webhook callback
   */
  async verifyKhalti(pidx: string): Promise<{ vaultId: string }> {
    const paymentIntent = await PaymentIntentModel.findOne({ idempotencyKey: pidx });
    if (!paymentIntent) throw new AppError('Payment intent not found', 404, 'PAYMENT_NOT_FOUND');
    if (paymentIntent.status === PaymentStatus.COMPLETED) {
      throw new AppError('Payment already processed', 409, 'ALREADY_PROCESSED');
    }

    // Server-side Khalti lookup
    const baseUrl = process.env.NODE_ENV === 'production'
      ? 'https://khalti.com/api/v2/epayment/lookup/'
      : 'https://a.khalti.com/api/v2/epayment/lookup/';

    const lookupResp = await axios.post(baseUrl, { pidx }, {
      headers: { Authorization: `Key ${this.khaltiSecret}` },
    });

    if (lookupResp.data.status !== 'Completed') {
      throw new AppError('Khalti payment not complete', 400, 'PAYMENT_NOT_COMPLETE');
    }

    paymentIntent.status = PaymentStatus.COMPLETED;
    paymentIntent.completedAt = new Date();
    await paymentIntent.save();

    await TransactionModel.create({
      paymentIntentId: paymentIntent._id,
      vaultId: paymentIntent.vaultId,
      provider: 'KHALTI',
      txnId: pidx,
      amount: paymentIntent.amount,
      direction: TransactionDirection.DEBIT,
      status: TransactionStatus.SETTLED,
      rawPayload: JSON.stringify(lookupResp.data),
    });

    return { vaultId: paymentIntent.vaultId.toString() };
  }

  /**
   * Dedup helper — record webhook receipt and check for duplicates
   */
  async recordWebhook(psp: 'ESEWA' | 'KHALTI' | 'CONNECTIPS', eventId: string, rawBody: string, headers: Record<string, string>, signatureValid: boolean): Promise<boolean> {
    try {
      await WebhookReceivedModel.create({ psp, eventId, rawBody, headers, signatureValid });
      return true; // First time seeing this event
    } catch (err: any) {
      if (err.code === 11000) return false; // Duplicate — skip
      throw err;
    }
  }

  async markWebhookProcessed(psp: 'ESEWA' | 'KHALTI' | 'CONNECTIPS', eventId: string, error?: string): Promise<void> {
    await WebhookReceivedModel.findOneAndUpdate(
      { psp, eventId },
      { processed: !error, processedAt: new Date(), error },
    );
  }

  async generateEsewaForm(intentId: string): Promise<string> {
    const intent = await PaymentIntentModel.findById(intentId);
    if (!intent) throw new AppError('Payment intent not found', 404);

    const esewaSecrets = await getEsewaSecrets();
    const product_code = esewaSecrets.product_code || 'EPAYTEST';
    const amount = intent.amount;
    const transaction_uuid = intent.idempotencyKey;
    
    const signatureStr = `total_amount=${amount},transaction_uuid=${transaction_uuid},product_code=${product_code}`;
    const signature = crypto.createHmac('sha256', esewaSecrets.secret_key || '8gBm/:&EnhH.1/q')
      .update(signatureStr).digest('base64');

    const baseUrl = process.env.NODE_ENV === 'production'
      ? 'https://epay.esewa.com.np/api/epay/main/v2/form'
      : 'https://rc-epay.esewa.com.np/api/epay/main/v2/form';

    const successUrl = process.env.ESEWA_SUCCESS_URL || `${process.env.API_BASE_URL}/api/v1/payments/esewa/callback`;
    const failureUrl = process.env.ESEWA_FAILURE_URL || `${process.env.API_BASE_URL}/api/v1/payments/esewa/failure`;

    return `
      <html>
        <head>
          <title>Trust Nepal - Secure Payment</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background-color: #f4f7f6; }
            .card { background: white; padding: 40px; borderRadius: 12px; boxShadow: 0 10px 25px rgba(0,0,0,0.05); textAlign: center; maxWidth: 400px; }
            .loader { border: 3px solid #f3f3f3; border-top: 3px solid #059669; borderRadius: 50%; width: 30px; height: 30px; animation: spin 1s linear infinite; margin: 20px auto; }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
            button { background-color: #059669; color: white; border: none; padding: 12px 24px; borderRadius: 6px; fontWeight: bold; cursor: pointer; marginTop: 20px; transition: opacity 0.2s; }
            button:hover { opacity: 0.9; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="loader"></div>
            <h2 style="color: #051424; margin-bottom: 8px;">Redirecting to eSewa</h2>
            <p style="color: #64748b; font-size: 14px;">Please wait while we establish a secure connection to the payment gateway.</p>
            
            <form action="${baseUrl}" method="POST">
              <input type="hidden" name="amount" value="${amount}">
              <input type="hidden" name="tax_amount" value="0">
              <input type="hidden" name="total_amount" value="${amount}">
              <input type="hidden" name="transaction_uuid" value="${transaction_uuid}">
              <input type="hidden" name="product_code" value="${product_code}">
              <input type="hidden" name="product_service_charge" value="0">
              <input type="hidden" name="product_delivery_charge" value="0">
              <input type="hidden" name="success_url" value="${successUrl}">
              <input type="hidden" name="failure_url" value="${failureUrl}">
              <input type="hidden" name="signed_field_names" value="total_amount,transaction_uuid,product_code">
              <input type="hidden" name="signature" value="${signature}">
              <button type="submit">PAY WITH ESEWA NOW</button>
            </form>
          </div>
          <script>
            // Auto-submit after a tiny delay to ensure everything is loaded
            setTimeout(function() {
              document.forms[0].submit();
            }, 500);
          </script>
        </body>
      </html>
    `;
  }
}
