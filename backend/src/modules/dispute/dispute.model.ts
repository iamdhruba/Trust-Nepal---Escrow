import mongoose, { Schema, Document } from 'mongoose';

export enum DisputeStatus {
  OPEN = 'OPEN',
  UNDER_REVIEW = 'UNDER_REVIEW',
  RESOLVED_BUYER = 'RESOLVED_BUYER',
  RESOLVED_SELLER = 'RESOLVED_SELLER',
  ESCALATED = 'ESCALATED'
}

export interface IDispute extends Document {
  vaultId: mongoose.Types.ObjectId;
  raisedBy: mongoose.Types.ObjectId;
  assignedTo?: mongoose.Types.ObjectId;
  status: DisputeStatus;
  reason: string;
  description: string;
  evidence: Array<{
    type: string;
    path: string;
    uploadedBy: mongoose.Types.ObjectId;
    at: Date;
  }>;
  messages: Array<{
    senderId: mongoose.Types.ObjectId;
    content: string;
    at: Date;
    isAdminOnly: boolean;
  }>;
  resolution?: {
    decision: string;
    reason: string;
    resolvedBy: mongoose.Types.ObjectId;
    resolvedAt: Date;
  };
  escalatedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const DisputeSchema: Schema = new Schema({
  vaultId: { type: Schema.Types.ObjectId, ref: 'Vault', required: true },
  raisedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  assignedTo: { type: Schema.Types.ObjectId, ref: 'User' },
  status: { type: String, enum: Object.values(DisputeStatus), default: DisputeStatus.OPEN },
  reason: { type: String, required: true },
  description: { type: String, required: true },
  evidence: [{
    type: String,
    path: String,
    uploadedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    at: { type: Date, default: Date.now }
  }],
  messages: [{
    senderId: { type: Schema.Types.ObjectId, ref: 'User' },
    content: String,
    at: { type: Date, default: Date.now },
    isAdminOnly: { type: Boolean, default: false }
  }],
  resolution: {
    decision: String,
    reason: String,
    resolvedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    resolvedAt: Date
  },
  escalatedAt: Date,
}, { timestamps: true });

export const DisputeModel = mongoose.model<IDispute>('Dispute', DisputeSchema);
