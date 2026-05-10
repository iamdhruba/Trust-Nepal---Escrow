import { DisputeModel, DisputeStatus, IDispute } from './dispute.model.js';
import { VaultService } from '../vault/vault.service.js';
import { AppError } from '../../errors/AppError.js';
import mongoose from 'mongoose';

export class DisputeService {
  private vaultService = new VaultService();

  async raiseDispute(data: any, actorId: string): Promise<IDispute> {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // 1. Create Dispute
      const dispute = new DisputeModel({
        vaultId: data.vaultId,
        raisedBy: actorId,
        reason: data.reason,
        description: data.description,
        evidence: data.evidence || []
      });
      await dispute.save({ session });

      // 2. Transition Vault to DISPUTED
      await this.vaultService.transition(
        data.vaultId,
        'dispute',
        actorId,
        'USER',
        { disputeId: dispute._id }
      );

      await session.commitTransaction();
      return dispute;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async resolveDispute(disputeId: string, resolution: any, adminId: string): Promise<IDispute> {
    const dispute = await DisputeModel.findById(disputeId);
    if (!dispute) throw new AppError('Dispute not found', 404, 'DISPUTE_NOT_FOUND');

    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      dispute.status = resolution.decision === 'BUYER' ? DisputeStatus.RESOLVED_BUYER : DisputeStatus.RESOLVED_SELLER;
      dispute.resolution = {
        decision: resolution.decision,
        reason: resolution.reason,
        resolvedBy: new mongoose.Types.ObjectId(adminId),
        resolvedAt: new Date()
      };
      await dispute.save({ session });

      // Transition Vault
      const action = resolution.decision === 'BUYER' ? 'resolve_buyer' : 'resolve_seller';
      await this.vaultService.transition(
        dispute.vaultId.toString(),
        action,
        adminId,
        'ADMIN',
        { resolutionReason: resolution.reason }
      );

      await session.commitTransaction();
      return dispute;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }
}
