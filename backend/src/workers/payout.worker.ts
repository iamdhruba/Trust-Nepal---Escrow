import pino from 'pino';
import { getAgenda } from '../config/agenda.js';
import { VaultModel } from '../modules/vault/vault.model.js';
import { UserModel } from '../modules/user/user.model.js';
import axios from 'axios';

const logger = pino({ name: 'payout-worker' });

export const definePayoutJobs = () => {
  const agenda = getAgenda();

  agenda.define('payout.initiate', async (job) => {
    const { vaultId, amount } = job.attrs.data as any;
    logger.info({ vaultId, amount }, 'Processing payout');
    
    try {
      const vault = await VaultModel.findById(vaultId);
      if (!vault) throw new Error('Vault not found');

      const seller = await UserModel.findById(vault.sellerId);
      if (!seller) throw new Error('Seller not found');

      // CRITICAL SECURITY FIX: Strict KYC & Bank Details Enforcement
      if (seller.kyc?.status !== 'VERIFIED') {
        logger.error({ vaultId, sellerId: seller._id, kycStatus: seller.kyc?.status }, 'Payout blocked: Seller KYC is not VERIFIED. Funds frozen until KYC completion.');
        throw new Error('Payout blocked: Seller KYC is not VERIFIED.');
      }

      if (!seller.bankDetails?.accountNumber || !seller.bankDetails?.bankName) {
        logger.error({ vaultId, sellerId: seller._id }, 'Payout blocked: Incomplete bank details.');
        throw new Error('Payout blocked: Incomplete bank details.');
      }

      // Attempt the actual bank transfer via the payment gateway API
      const payoutResponse = await axios.post(
        `${process.env.PAYMENT_GATEWAY_URL || 'https://api.gateway.com/v1'}/payout`,
        {
          amount: amount,
          currency: vault.currency || 'NPR',
          beneficiary: {
            accountName: seller.bankDetails.accountName,
            accountNumber: seller.bankDetails.accountNumber,
            bankCode: seller.bankDetails.bankName,
          },
          referenceId: vaultId,
          remarks: `Trust Nepal Escrow Payout for ${vault.title}`
        },
        {
          headers: {
            'Authorization': `Bearer ${process.env.PAYMENT_GATEWAY_SECRET}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (payoutResponse.data.status !== 'SUCCESS') {
        throw new Error(`Bank transfer failed: ${payoutResponse.data.message || 'Unknown error'}`);
      }

      logger.info({ 
        vaultId, 
        amount, 
        bankName: seller.bankDetails.bankName, 
        accountNumber: seller.bankDetails.accountNumber,
        transactionId: payoutResponse.data.transactionId
      }, 'Payout successfully transferred to verified bank account');

    } catch (error: any) {
      logger.error({ vaultId, error: error.message }, 'Payout failed');
      throw error;
    }
  });

  // ── REFUND JOB: Returns funds to buyer ──
  agenda.define('payout.refund', async (job) => {
    const { vaultId, amount } = job.attrs.data as any;
    logger.info({ vaultId, amount }, 'Processing refund to buyer');
    
    try {
      const vault = await VaultModel.findById(vaultId);
      if (!vault) throw new Error('Vault not found');

      const buyer = await UserModel.findById(vault.buyerId);
      if (!buyer) throw new Error('Buyer not found');

      // Note: We typically refund to the same source, but if it's a bank transfer, 
      // we need their verified bank details as well.
      if (!buyer.bankDetails?.accountNumber) {
        logger.error({ vaultId, buyerId: buyer._id }, 'Refund blocked: Buyer bank details missing.');
        throw new Error('Refund blocked: Buyer bank details missing.');
      }

      
      const refundResponse = await axios.post(
        `${process.env.PAYMENT_GATEWAY_URL || 'https://api.gateway.com/v1'}/refund`,
        {
          amount: amount,
          originalReferenceId: vaultId,
          beneficiary: {
            accountName: buyer.bankDetails.accountName,
            accountNumber: buyer.bankDetails.accountNumber,
            bankCode: buyer.bankDetails.bankName,
          },
          remarks: `Trust Nepal Escrow Refund for ${vault.title}`
        },
        {
          headers: {
            'Authorization': `Bearer ${process.env.PAYMENT_GATEWAY_SECRET}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (refundResponse.data.status !== 'SUCCESS') {
        throw new Error(`Refund failed: ${refundResponse.data.message || 'Unknown error'}`);
      }

      logger.info({ 
        vaultId, 
        amount, 
        transactionId: refundResponse.data.transactionId 
      }, 'Refund successfully transferred back to buyer');

    } catch (error: any) {
      logger.error({ vaultId, error: error.message }, 'Refund failed');
      throw error;
    }
  });
};
