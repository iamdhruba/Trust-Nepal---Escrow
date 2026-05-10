import mongoose, { Schema, Document } from 'mongoose';

export enum VaultState {
  INITIATED = 'INITIATED',
  FUNDED = 'FUNDED',
  SHIPPED = 'SHIPPED',
  DELIVERED = 'DELIVERED',
  COMPLETED = 'COMPLETED',
  REFUNDED = 'REFUNDED',
  DISPUTED = 'DISPUTED',
  ADMIN_REVIEW = 'ADMIN_REVIEW',
  CANCELLED = 'CANCELLED'
}

export interface IVault extends Document {
  buyerId: mongoose.Types.ObjectId;
  sellerId: mongoose.Types.ObjectId;
  title: string;
  description: string;
  amount: number;
  currency: string;
  platformFee: number;
  netSellerAmount: number;
  state: VaultState;
  stateHistory: Array<{
    state: VaultState;
    at: Date;
    by: mongoose.Types.ObjectId | string; // userId or 'system'
  }>;
  paymentIntentId?: mongoose.Types.ObjectId;
  category: string;
  trackingNumber?: string;
  courierCode?: string;
  deliveryQRToken?: string;
  currentHash: string;
  expiresAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const VaultSchema: Schema = new Schema({
  buyerId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  sellerId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  category: { type: String, default: 'General' },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'NPR' },
  platformFee: { type: Number, default: 0 },
  netSellerAmount: { type: Number, required: true },
  state: { type: String, enum: Object.values(VaultState), default: VaultState.INITIATED },
  stateHistory: [{
    state: { type: String, enum: Object.values(VaultState) },
    at: { type: Date, default: Date.now },
    by: Schema.Types.Mixed
  }],
  paymentIntentId: { type: Schema.Types.ObjectId, ref: 'PaymentIntent' },
  trackingNumber: String,
  courierCode: String,
  deliveryQRToken: String,
  currentHash: { type: String, required: true },
  expiresAt: { type: Date, required: true },
}, { timestamps: true });

// Indexes for performance
VaultSchema.index({ buyerId: 1, createdAt: -1 });
VaultSchema.index({ sellerId: 1, createdAt: -1 });
VaultSchema.index({ state: 1 });
VaultSchema.index({ paymentIntentId: 1 }, { sparse: true });

export const VaultModel = mongoose.model<IVault>('Vault', VaultSchema);
