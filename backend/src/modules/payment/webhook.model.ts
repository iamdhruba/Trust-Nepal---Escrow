import mongoose, { Schema, Document } from 'mongoose';

export interface IWebhookReceived extends Document {
  psp: 'ESEWA' | 'KHALTI' | 'CONNECTIPS';
  eventId: string;
  rawBody: string;
  headers: Record<string, string>;
  signatureValid: boolean;
  processed: boolean;
  processedAt?: Date;
  error?: string;
  receivedAt: Date;
}

const WebhookReceivedSchema: Schema = new Schema({
  psp: { type: String, enum: ['ESEWA', 'KHALTI', 'CONNECTIPS'], required: true },
  eventId: { type: String, required: true },
  rawBody: { type: String, required: true },
  headers: { type: Map, of: String },
  signatureValid: { type: Boolean, required: true },
  processed: { type: Boolean, default: false },
  processedAt: Date,
  error: String,
  receivedAt: { type: Date, default: Date.now },
});

// Unique index per (psp, eventId) — dedup guarantee
WebhookReceivedSchema.index({ psp: 1, eventId: 1 }, { unique: true });

export const WebhookReceivedModel = mongoose.model<IWebhookReceived>('WebhookReceived', WebhookReceivedSchema);
