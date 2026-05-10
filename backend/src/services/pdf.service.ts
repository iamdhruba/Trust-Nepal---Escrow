import puppeteer from 'puppeteer';
import path from 'path';
import fs from 'fs';
import { IVault } from '../modules/vault/vault.model.js';

export class PDFService {
  static async generateVaultReceipt(vault: IVault, buyer: any, seller: any): Promise<Buffer> {
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    
    const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: 'Helvetica', sans-serif; padding: 40px; color: #333; }
        .header { display: flex; justify-content: space-between; border-bottom: 2px solid #10B981; padding-bottom: 20px; }
        .logo { font-size: 24px; font-weight: bold; color: #10B981; }
        .receipt-title { font-size: 28px; text-transform: uppercase; color: #111; }
        .section { margin-top: 30px; }
        .section-title { font-weight: bold; border-bottom: 1px solid #eee; padding-bottom: 5px; margin-bottom: 10px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .label { color: #666; font-size: 12px; }
        .value { font-size: 16px; margin-top: 4px; }
        .footer { margin-top: 50px; text-align: center; font-size: 10px; color: #999; border-top: 1px solid #eee; padding-top: 20px; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
        .badge-success { background: #D1FAE5; color: #065F46; }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="logo">TRUST NEPAL</div>
        <div class="receipt-title">Transaction Receipt</div>
      </div>

      <div class="section">
        <div class="section-title">VAULT INFORMATION</div>
        <div class="grid">
          <div>
            <div class="label">Vault Title</div>
            <div class="value">${vault.title}</div>
          </div>
          <div>
            <div class="label">Status</div>
            <div class="value"><span class="badge badge-success">${vault.state}</span></div>
          </div>
          <div>
            <div class="label">Vault ID</div>
            <div class="value">${vault._id}</div>
          </div>
          <div>
            <div class="label">Amount</div>
            <div class="value">${vault.amount} ${vault.currency || 'NPR'}</div>
          </div>
        </div>
      </div>

      <div class="section">
        <div class="section-title">PARTICIPANTS</div>
        <div class="grid">
          <div>
            <div class="label">Buyer</div>
            <div class="value">${buyer.phone}</div>
          </div>
          <div>
            <div class="label">Seller</div>
            <div class="value">${seller.phone}</div>
          </div>
        </div>
      </div>

      <div class="section">
        <div class="section-title">DATES</div>
        <div class="grid">
          <div>
            <div class="label">Created At</div>
            <div class="value">${new Date(vault.createdAt).toLocaleString()}</div>
          </div>
          <div>
            <div class="label">Last Updated</div>
            <div class="value">${new Date(vault.updatedAt).toLocaleString()}</div>
          </div>
        </div>
      </div>

      <div class="footer">
        This is a computer-generated document. No signature is required.<br>
        &copy; ${new Date().getFullYear()} Trust Nepal Escrow Services. All rights reserved.
      </div>
    </body>
    </html>
    `;

    await page.setContent(htmlContent);
    const pdfBuffer = await page.pdf({ format: 'A4' });
    
    await browser.close();
    return Buffer.from(pdfBuffer);
  }
}
