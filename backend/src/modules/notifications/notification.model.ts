import mongoose, { Schema, Document } from 'mongoose';

export interface INotification extends Document {
  userId: mongoose.Types.ObjectId;
  type: string;
  title: string;
  body: string;
  data?: Record<string, any>;
  read: boolean;
  createdAt: Date;
}

const NotificationSchema: Schema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  type: { type: String, required: true },
  title: { type: String, required: true },
  body: { type: String, required: true },
  data: { type: Schema.Types.Mixed },
  read: { type: Boolean, default: false },
}, { timestamps: { createdAt: true, updatedAt: false } });

NotificationSchema.index({ userId: 1, createdAt: -1 });

export const NotificationModel = mongoose.model<INotification>('Notification', NotificationSchema);

// ── Helper: create a notification ─────────────────────────────────────────
export async function createNotification(
  userId: string,
  type: string,
  title: string,
  body: string,
  data?: Record<string, any>,
): Promise<INotification> {
  return await NotificationModel.create({ userId, type, title, body, data });
}
