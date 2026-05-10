import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  phone: string;
  email?: string;
  role: string[];
  isActive: boolean;
  kyc: {
    status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'RESUBMIT' | 'NOT_SUBMITTED';
    submittedAt?: Date;
    reviewedAt?: Date;
    reviewedBy?: mongoose.Types.ObjectId;
    rejectionReason?: string;
    fullName?: string;
    dob?: Date;
    idType?: string;
    idNumber?: string;
    idFrontPath?: string;
    idBackPath?: string;
    selfiePath?: string;
    address?: string;
  };
  bankDetails?: {
    accountName: string;
    accountNumber: string;
    bankName: string;
  };
  deviceFingerprints: string[];
  fcmTokens: string[];
  refreshTokens: Array<{
    token: string;
    deviceId: string;
    expiresAt: Date;
  }>;
  language: 'en' | 'ne';
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema: Schema = new Schema({
  phone: { type: String, required: true, unique: true },
  email: { type: String, sparse: true },
  role: { type: [String], default: ['BUYER'] },
  isActive: { type: Boolean, default: true },
  fcmTokens: { type: [String], default: [] },
  language: { type: String, enum: ['en', 'ne'], default: 'en' },
  kyc: {
    status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED', 'RESUBMIT', 'NOT_SUBMITTED'], default: 'NOT_SUBMITTED' },
    submittedAt: Date,
    reviewedAt: Date,
    reviewedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    rejectionReason: String,
    fullName: String,
    dob: Date,
    idType: String,
    idNumber: String,
    idFrontPath: String,
    idBackPath: String,
    selfiePath: String,
    address: String,
  },
  bankDetails: {
    accountName: String,
    accountNumber: String,
    bankName: String,
  },
  deviceFingerprints: [String],
  refreshTokens: [{
    token: { type: String, required: true },
    deviceId: { type: String, required: true },
    expiresAt: { type: Date, required: true },
  }],
}, { timestamps: true });

UserSchema.index({ 'refreshTokens.token': 1 });
UserSchema.index({ 'kyc.status': 1 });

export const UserModel = mongoose.model<IUser>('User', UserSchema);
