import mongoose, { Schema, Document } from 'mongoose';

export interface IMessage extends Document {
  vaultId: mongoose.Types.ObjectId;
  senderId: mongoose.Types.ObjectId;
  content: string;
  type: 'text' | 'image' | 'system';
  createdAt: Date;
}

const MessageSchema: Schema = new Schema({
  vaultId: { type: Schema.Types.ObjectId, ref: 'Vault', required: true },
  senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  content: { type: String, required: true },
  type: { type: String, enum: ['text', 'image', 'system'], default: 'text' },
}, { timestamps: true });

MessageSchema.index({ vaultId: 1, createdAt: 1 });

export const MessageModel = mongoose.model<IMessage>('Message', MessageSchema);
