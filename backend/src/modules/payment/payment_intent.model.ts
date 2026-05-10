import mongoose, { Schema, Document } from 'mongoose';

export enum PaymentProvider {
  ESEWA = 'ESEWA',
  KHALTI = 'KHALTI',
  CONNECTIPS = 'CONNECTIPS'
}

export enum PaymentStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  EXPIRED = 'EXPIRED',
  CANCELLED = 'CANCELLED'
}

export interface IPaymentIntent extends Document {
  vaultId: mongoose.Types.ObjectId;
  provider: PaymentProvider;
  amount: number;
  currency: string;
  status: PaymentStatus;
  idempotencyKey: string;
  pspReference?: string;
  pspRawResponse?: any;
  initiatedAt: Date;
  completedAt?: Date;
  expiresAt: Date;
  retryCount: number;
  lastError?: string;
}

const PaymentIntentSchema: Schema = new Schema({
  vaultId: { type: Schema.Types.ObjectId, ref: 'Vault', required: true },
  provider: { type: String, enum: Object.values(PaymentProvider), required: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'NPR' },
  status: { type: String, enum: Object.values(PaymentStatus), default: PaymentStatus.PENDING },
  idempotencyKey: { type: String, required: true, unique: true },
  pspReference: String,
  pspRawResponse: Schema.Types.Mixed,
  initiatedAt: { type: Date, default: Date.now },
  completedAt: Date,
  expiresAt: { type: Date, required: true },
  retryCount: { type: Number, default: 0 },
  lastError: String,
}, { timestamps: true });

PaymentIntentSchema.index({ vaultId: 1, status: 1 });

export const PaymentIntentModel = mongoose.model<IPaymentIntent>('PaymentIntent', PaymentIntentSchema);
