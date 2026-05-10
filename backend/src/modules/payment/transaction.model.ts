import mongoose, { Schema, Document } from 'mongoose';

export enum TransactionDirection {
  DEBIT = 'DEBIT',
  CREDIT = 'CREDIT',
}

export enum TransactionStatus {
  PENDING = 'PENDING',
  SETTLED = 'SETTLED',
  FAILED = 'FAILED',
  REVERSED = 'REVERSED',
}

export interface ITransaction extends Document {
  paymentIntentId: mongoose.Types.ObjectId;
  vaultId: mongoose.Types.ObjectId;
  provider: 'ESEWA' | 'KHALTI' | 'CONNECTIPS';
  txnId: string; // PSP transaction ID
  amount: number;
  currency: string;
  direction: TransactionDirection;
  status: TransactionStatus;
  reconciledAt?: Date;
  reconciliationBatchId?: string;
  rawPayload: string; // Encrypted at rest
  createdAt: Date;
}

const TransactionSchema: Schema = new Schema({
  paymentIntentId: { type: Schema.Types.ObjectId, ref: 'PaymentIntent', required: true },
  vaultId: { type: Schema.Types.ObjectId, ref: 'Vault', required: true },
  provider: { type: String, enum: ['ESEWA', 'KHALTI', 'CONNECTIPS'], required: true },
  txnId: { type: String, required: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'NPR' },
  direction: { type: String, enum: Object.values(TransactionDirection), required: true },
  status: { type: String, enum: Object.values(TransactionStatus), default: TransactionStatus.PENDING },
  reconciledAt: Date,
  reconciliationBatchId: String,
  rawPayload: { type: String, required: true },
}, { timestamps: true });

TransactionSchema.index({ vaultId: 1 });
TransactionSchema.index({ status: 1, reconciledAt: 1 });
TransactionSchema.index({ provider: 1, txnId: 1 }, { unique: true });

export const TransactionModel = mongoose.model<ITransaction>('Transaction', TransactionSchema);
