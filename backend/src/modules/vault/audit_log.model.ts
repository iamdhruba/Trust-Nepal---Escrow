import mongoose, { Schema, Document } from 'mongoose';

export interface IAuditLog extends Document {
  vaultId: mongoose.Types.ObjectId;
  action: string;
  actorId: mongoose.Types.ObjectId | string;
  actorRole: string;
  prevHash: string;
  hash: string;
  payload: any;
  timestamp: Date;
  ipAddress?: string;
  userAgent?: string;
}

const AuditLogSchema: Schema = new Schema({
  vaultId: { type: Schema.Types.ObjectId, ref: 'Vault', required: true },
  action: { type: String, required: true },
  actorId: { type: Schema.Types.Mixed, required: true },
  actorRole: { type: String, required: true },
  prevHash: { type: String, required: true },
  hash: { type: String, required: true },
  payload: { type: Schema.Types.Mixed },
  timestamp: { type: Date, default: Date.now },
  ipAddress: String,
  userAgent: String,
}, { timestamps: false });

// Ensure immutability via index
AuditLogSchema.index({ vaultId: 1, timestamp: 1 });
AuditLogSchema.index({ actorId: 1, timestamp: 1 });

export const AuditLogModel = mongoose.model<IAuditLog>('AuditLog', AuditLogSchema);
