import { getAgenda } from '../config/agenda.js';
import puppeteer from 'puppeteer';
import { VaultModel } from '../modules/vault/vault.model.js';
import pino from 'pino';
import path from 'path';
import fs from 'fs';

const logger = pino({ name: 'invoice-worker' });

function buildInvoiceHTML(vault: any, buyer: any, seller: any): string {
  const date = new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'long', year: 'numeric' });
  const fee = (vault.amount * 0.015).toFixed(2);
  return `
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  body { font-family: 'Helvetica Neue', Arial, sans-serif; color: #1a1a2e; margin: 0; padding: 40px; background: #fff; }
  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 3px solid #10B981; padding-bottom: 20px; margin-bottom: 30px; }
  .logo { font-size: 28px; font-weight: 900; color: #10B981; letter-spacing: -1px; }
  .badge { background: #051424; color: #D4AF37; font-size: 10px; font-weight: 700; padding: 4px 10px; border-radius: 4px; letter-spacing: 1.5px; }
  .title { font-size: 22px; font-weight: 700; margin-bottom: 4px; }
  .meta { color: #64748b; font-size: 13px; }
  table { width: 100%; border-collapse: collapse; margin: 24px 0; }
  th { background: #f8fafc; text-align: left; padding: 10px 14px; font-size: 11px; letter-spacing: 1px; color: #64748b; border-bottom: 2px solid #e2e8f0; }
  td { padding: 12px 14px; border-bottom: 1px solid #f1f5f9; font-size: 14px; }
  .total-row td { font-weight: 700; font-size: 16px; background: #f0fdf4; color: #065f46; border-top: 2px solid #10B981; }
  .footer { margin-top: 40px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0; padding-top: 20px; }
  .parties { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 24px 0; }
  .party-box { background: #f8fafc; border-radius: 8px; padding: 16px; border: 1px solid #e2e8f0; }
  .party-label { font-size: 10px; font-weight: 700; letter-spacing: 1px; color: #64748b; margin-bottom: 6px; }
</style>
</head>
<body>
  <div class="header">
    <div>
      <div class="logo">Trust Nepal</div>
      <div style="color:#64748b;font-size:12px;margin-top:4px;">NRB Licensed Escrow Platform</div>
    </div>
    <div style="text-align:right;">
      <div class="badge">E-INVOICE</div>
      <div style="margin-top:8px;font-size:13px;color:#64748b;">${date}</div>
      <div style="font-size:12px;color:#94a3b8;">Invoice #TN-${vault._id.toString().slice(-8).toUpperCase()}</div>
    </div>
  </div>

  <div class="parties">
    <div class="party-box">
      <div class="party-label">BUYER</div>
      <div style="font-weight:600;">${buyer.phone}</div>
      <div style="color:#64748b;font-size:12px;">${buyer.email || '—'}</div>
    </div>
    <div class="party-box">
      <div class="party-label">SELLER</div>
      <div style="font-weight:600;">${seller.phone}</div>
      <div style="color:#64748b;font-size:12px;">${seller.email || '—'}</div>
    </div>
  </div>

  <div class="title">${vault.title}</div>
  <div class="meta">Vault ID: ${vault._id} &nbsp;|&nbsp; State: FUNDED</div>

  <table>
    <thead>
      <tr><th>DESCRIPTION</th><th>AMOUNT (NPR)</th></tr>
    </thead>
    <tbody>
      <tr><td>Escrow Principal Amount</td><td>Rs. ${vault.amount.toFixed(2)}</td></tr>
      <tr><td>Platform Fee (1.5%)</td><td>Rs. ${fee}</td></tr>
      <tr class="total-row"><td>TOTAL LOCKED IN ESCROW</td><td>Rs. ${vault.amount.toFixed(2)}</td></tr>
      <tr><td style="color:#64748b;">Net Seller Payout (on completion)</td><td style="color:#64748b;">Rs. ${vault.netSellerAmount.toFixed(2)}</td></tr>
    </tbody>
  </table>

  <div class="footer">
    <strong>Trust Nepal Escrow Pvt. Ltd.</strong> &nbsp;|&nbsp; NRB Licensed &nbsp;|&nbsp; AES-256 Encrypted<br>
    This is a computer-generated invoice. No signature required. &nbsp;|&nbsp; Funds held in licensed Class-A bank escrow account.<br>
    Questions? support@trustnepal.com.np &nbsp;|&nbsp; +977-1-XXXXXXX
  </div>
</body>
</html>`;
}

export const defineInvoiceJobs = () => {
  const agenda = getAgenda();

  agenda.define('invoice.generate', async (job: any) => {
    const { vaultId } = job.attrs.data;
    logger.info({ vaultId }, 'Generating invoice');

    const vault = await VaultModel.findById(vaultId)
      .populate('buyerId', 'phone email')
      .populate('sellerId', 'phone email');

    if (!vault) {
      logger.warn({ vaultId }, 'Vault not found, skipping invoice');
      return;
    }

    const html = buildInvoiceHTML(vault, vault.buyerId, vault.sellerId);

    let browser;
    try {
      browser = await puppeteer.launch({
        executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: true,
      });
      const page = await browser.newPage();
      await page.setContent(html, { waitUntil: 'networkidle0' });
      const pdfBuffer = await page.pdf({ format: 'A4', printBackground: true, margin: { top: '0', bottom: '0', left: '0', right: '0' } });

      // Store locally
      const invoicePath = path.join(process.cwd(), 'uploads', 'invoices', `${vaultId}.pdf`);
      const invoiceDir = path.dirname(invoicePath);
      if (!fs.existsSync(invoiceDir)) fs.mkdirSync(invoiceDir, { recursive: true });
      fs.writeFileSync(invoicePath, pdfBuffer);

      logger.info({ vaultId, invoicePath }, 'Invoice generated and stored locally');
    } catch (error: any) {
      logger.error({ vaultId, error: error.message }, 'Invoice generation failed');
      throw error;
    } finally {
      if (browser) await browser.close();
    }
  });
};
