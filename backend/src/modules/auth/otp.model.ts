import mongoose, { Schema, Document } from 'mongoose';

export interface IOTP extends Document {
  phone: string;
  otp: string;
  expiresAt: Date;
  verified: boolean;
  attempts: number;
}

const OTPSchema: Schema = new Schema({
  phone: { type: String, required: true },
  otp: { type: String, required: true },
  expiresAt: { type: Date, required: true },
  verified: { type: Boolean, default: false },
  attempts: { type: Number, default: 0 },
}, { timestamps: true });

// TTL index to automatically delete expired OTPs
OTPSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
OTPSchema.index({ phone: 1, createdAt: -1 });

export const OTPModel = mongoose.model<IOTP>('OTP', OTPSchema);
