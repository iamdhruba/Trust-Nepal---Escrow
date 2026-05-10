import mongoose from 'mongoose';
import crypto from 'crypto';
import { VaultModel, VaultState, IVault } from './vault.model.js';
import { AuditLogModel } from './audit_log.model.js';
import { AppError } from '../../errors/AppError.js';
import { 
  invoiceQueue, 
  notificationQueue, 
  payoutQueue, 
  refundQueue 
} from '../../config/queue.js';
import { BUSINESS_RULES } from '../../config/business.js';
import { getAuditSecret } from '../../config/secrets.js';
import { UserModel } from '../user/user.model.js';
import { normalizePhone } from '../../utils/phone.js';

export class VaultService {
  private static transitionRules: Record<string, VaultState[]> = {
    'fund': [VaultState.FUNDED],
    'ship': [VaultState.SHIPPED],
    'deliver': [VaultState.DELIVERED],
    'confirm': [VaultState.COMPLETED],
    'cancel': [VaultState.CANCELLED],
    'dispute': [VaultState.DISPUTED],
  };

  private static stateGuards: Record<VaultState, VaultState[]> = {
    [VaultState.INITIATED]: [],
    [VaultState.FUNDED]: [VaultState.INITIATED],
    [VaultState.SHIPPED]: [VaultState.FUNDED],
    [VaultState.DELIVERED]: [VaultState.SHIPPED],
    [VaultState.COMPLETED]: [VaultState.DELIVERED, VaultState.SHIPPED, VaultState.DISPUTED],
    [VaultState.REFUNDED]: [VaultState.FUNDED, VaultState.SHIPPED, VaultState.DISPUTED],
    [VaultState.DISPUTED]: [VaultState.FUNDED, VaultState.SHIPPED, VaultState.DELIVERED],
    [VaultState.ADMIN_REVIEW]: [VaultState.DISPUTED],
    [VaultState.CANCELLED]: [VaultState.INITIATED],
  };

  async transition(
    vaultId: string,
    action: string,
    actorId: string,
    actorRole: string,
    payload: any = {}
  ): Promise<IVault> {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const vault = await VaultModel.findById(vaultId).session(session);
        if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');

        const nextStates = VaultService.transitionRules[action];
        if (!nextStates) throw new AppError('Invalid action', 400, 'INVALID_ACTION');

        const nextState = nextStates[0]!;
        const allowedPreviousStates = VaultService.stateGuards[nextState];

        if (allowedPreviousStates && !allowedPreviousStates.includes(vault.state)) {
          throw new AppError(
            `Invalid transition from ${vault.state} to ${nextState}`,
            422,
            'INVALID_TRANSITION'
          );
        }

        const timestamp = new Date();
        const prevHash = vault.currentHash;
        const hashPayload = prevHash + vaultId + action + actorId + timestamp.toISOString() + JSON.stringify(payload);
        
        // Securely fetch audit secret from Secrets Manager
        const auditSecret = await getAuditSecret();
        
        const newHash = crypto.createHmac('sha256', auditSecret)
          .update(hashPayload)
          .digest('hex');

        vault.state = nextState;
        vault.currentHash = newHash;
        vault.stateHistory.push({ state: nextState, at: timestamp, by: actorId });
        await vault.save({ session });

        await AuditLogModel.create([{
          vaultId,
          action,
          actorId,
          actorRole,
          prevHash,
          hash: newHash,
          payload,
          timestamp,
        }], { session });

        await session.commitTransaction();

        // SIDE EFFECTS (Post-Commit)
        await this.handleSideEffects(vault, action, payload);

        return vault;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  private async handleSideEffects(vault: IVault, action: string, payload: any): Promise<void> {
    const vaultId = vault._id.toString();

    // 1. Notifications (Always)
    await notificationQueue.add('send', {
      vaultId,
      state: vault.state,
      buyerId: vault.buyerId,
      sellerId: vault.sellerId
    }).catch(err => console.error('Failed to add notification job', err));

    // 2. Real-time Vault State Update
    try {
      const { getIO } = await import('../../config/socket.js');
      const io = getIO();
      io.to(`vault:${vaultId}`).emit('vault_state_changed', {
        vaultId,
        state: vault.state,
        action
      });
      console.log(`[SOCKET] Emitted vault_state_changed for vault ${vaultId} to state ${vault.state}`);
    } catch (err) {
      console.error('Failed to emit vault state change via socket', err);
    }

    // 3. State-specific side effects
    switch (action) {
      case 'fund':
        await invoiceQueue.add('generate', { vaultId }).catch(err => console.error('Failed to add invoice job', err));
        break;
      
      case 'confirm':
      case 'resolve_seller': // Admin resolution
        await payoutQueue.add('payout', { vaultId, amount: vault.netSellerAmount }).catch(err => console.error('Failed to add payout job', err));
        break;

      case 'timeout': // System auto-refund
      case 'resolve_buyer': // Admin resolution
        await refundQueue.add('refund', { vaultId, amount: vault.amount }).catch(err => console.error('Failed to add refund job', err));
        break;
    }
  }

  async createVault(data: any, actorId: string): Promise<IVault> {
    try {
      const auditSecret = await getAuditSecret();
      const initialHash = crypto.createHmac('sha256', auditSecret)
        .update(`INIT-${actorId}-${Date.now()}`)
        .digest('hex');

      const platformFee = data.amount * BUSINESS_RULES.PLATFORM_FEE_PERCENTAGE;
      const netSellerAmount = data.amount - platformFee;

      // Resolve sellerId from phone
      const normalizedSellerPhone = normalizePhone(data.sellerPhone);
      let seller = await UserModel.findOne({ phone: normalizedSellerPhone });
      if (!seller) {
        console.log(`[VAULT_SERVICE] Creating shadow user for seller: ${normalizedSellerPhone}`);
        seller = await UserModel.create({ 
          phone: normalizedSellerPhone, 
          role: ['SELLER'],
          isActive: true,
          language: 'en',
          kyc: { status: 'NOT_SUBMITTED', fullName: data.sellerName },
          bankDetails: {
            accountNumber: data.sellerBank,
            accountName: data.sellerName,
            bankName: data.bankName || 'Unknown Bank'
          }
        });
      } else {
        // Update details if they were empty
        let updated = false;
        if (!seller.kyc?.fullName && data.sellerName) {
          seller.kyc.fullName = data.sellerName;
          updated = true;
        }
        if (!seller.bankDetails?.accountNumber && data.sellerBank) {
          seller.bankDetails = {
            accountNumber: data.sellerBank,
            accountName: data.sellerName || seller.kyc?.fullName || 'Unknown',
            bankName: data.bankName || 'Unknown Bank'
          };
          updated = true;
        }
        if (updated) await seller.save();
      }

      const vault = new VaultModel({
        ...data,
        description: data.description || `Trust Nepal Escrow Protection for: ${data.title}`,
        category: data.category || 'General',
        buyerId: actorId,
        sellerId: seller._id,
        platformFee,
        netSellerAmount,
        currentHash: initialHash,
        expiresAt: new Date(Date.now() + BUSINESS_RULES.DEFAULT_VAULT_EXPIRY_DAYS * 24 * 60 * 60 * 1000),
        stateHistory: [{ state: VaultState.INITIATED, at: new Date(), by: actorId }]
      });

      const saved = await vault.save();
      console.log(`[VAULT_SERVICE] Vault created: ${saved._id}`);

      // Notify parties about new vault
      await notificationQueue.add('send', {
        vaultId: saved._id.toString(),
        state: saved.state,
        buyerId: saved.buyerId.toString(),
        sellerId: saved.sellerId.toString()
      }).catch(err => console.error('Failed to add notification job', err));

      return saved;
    } catch (error: any) {
      console.error('[VAULT_SERVICE_ERROR] Failed to create vault:', error);
      throw error;
    }
  }

  async generateDeliveryQR(vaultId: string, actorId: string): Promise<string> {
    const vault = await VaultModel.findById(vaultId);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    if (vault.buyerId.toString() !== actorId) throw new AppError('Unauthorized', 403, 'UNAUTHORIZED');

    const qrToken = crypto.randomBytes(32).toString('hex');
    vault.deliveryQRToken = qrToken;
    await vault.save();

    return qrToken;
  }

  async validateDeliveryQR(vaultId: string, qrToken: string, actorId: string): Promise<IVault> {
    const vault = await VaultModel.findById(vaultId);
    if (!vault) throw new AppError('Vault not found', 404, 'VAULT_NOT_FOUND');
    if (vault.sellerId.toString() !== actorId) throw new AppError('Unauthorized', 403, 'UNAUTHORIZED');

    if (vault.deliveryQRToken !== qrToken) {
      throw new AppError('Invalid QR token', 400, 'INVALID_QR_TOKEN');
    }

    return this.transition(vaultId, 'deliver', actorId, 'SELLER');
  }

  async getAuditLogs(vaultId: string): Promise<any[]> {
    return AuditLogModel.find({ vaultId }).sort({ timestamp: 1 });
  }
}
