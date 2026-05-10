import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { OTPModel } from './otp.model.js';
import { UserModel } from '../user/user.model.js';
import { UnauthorizedError, AppError } from '../../errors/AppError.js';
import { getFirebaseAdmin } from '../../config/firebase.js';

let PRIVATE_KEY = '';
let PUBLIC_KEY = '';

try {
  PRIVATE_KEY = process.env.JWT_PRIVATE_KEY?.replace(/\\n/g, '\n') || fs.readFileSync(path.join(process.cwd(), 'keys/private.pem'), 'utf8');
  PUBLIC_KEY = process.env.JWT_PUBLIC_KEY?.replace(/\\n/g, '\n') || fs.readFileSync(path.join(process.cwd(), 'keys/public.pem'), 'utf8');
} catch (error) {
  console.warn('[WARN] Could not load JWT RSA keys. Error:', error);
}

// In-memory rate limiting for OTP
const otpRateLimit = new Map<string, { count: number, resetAt: number }>();

export class AuthService {
  async sendOTP(phone: string): Promise<void> {
    const now = Date.now();
    const limit = otpRateLimit.get(phone);

    if (limit && limit.resetAt > now) {
      if (limit.count >= 5) {
        throw new AppError('Too many OTP requests. Please try again later.', 429, 'RATE_LIMIT_EXCEEDED');
      }
      limit.count++;
    } else {
      otpRateLimit.set(phone, { count: 1, resetAt: now + 3600 * 1000 }); // 1 hour window
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    await OTPModel.create({ phone, otp, expiresAt });

    // Mock SMS sending
    console.log(`[SMS] To: ${phone}, OTP: ${otp}`);
    
    // In production, call Sparrow SMS API here
    if (process.env.NODE_ENV === 'production' && process.env.SMS_API_KEY) {
      try {
        const response = await fetch('http://api.sparrowsms.com/v2/sms/', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            token: process.env.SMS_API_KEY,
            from: 'Demo', // Should be registered Sender ID
            to: phone,
            text: `Your Trust Nepal verification code is ${otp}. It expires in 5 minutes. Do not share this code.`,
          }),
        });
        
        if (!response.ok) {
          const err = await response.text();
          console.error(`[SMS_ERROR] Failed to send OTP to ${phone}:`, err);
        }
      } catch (err) {
        console.error(`[SMS_ERROR] Network error sending OTP to ${phone}:`, err);
      }
    }
  }

  async verifyFirebaseToken(idToken: string, deviceId: string, fingerprint: string): Promise<{ accessToken: string, refreshToken: string }> {
    try {
      const admin = getFirebaseAdmin();
      console.log('[DEBUG] Verifying Firebase ID Token...');
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      console.log('[DEBUG] Decoded Token:', JSON.stringify(decodedToken, null, 2));
      const phone = decodedToken.phone_number;

      if (!phone) {
        console.error('[DEBUG] Phone number missing in token');
        throw new UnauthorizedError('Phone number not found in Firebase token');
      }

      console.log(`[DEBUG] Token verified for phone: ${phone}`);

      let user = await UserModel.findOne({ phone });
      if (!user) {
        user = await UserModel.create({ phone, role: ['BUYER'], deviceFingerprints: [fingerprint] });
      } else {
        if (!user.deviceFingerprints.includes(fingerprint)) {
          user.deviceFingerprints.push(fingerprint);
          await user.save();
        }
      }

      return this.issueTokens(user.id, deviceId);
    } catch (error: any) {
      console.error('[FIREBASE_VERIFY_ERROR] Full error:', error);
      console.error('[FIREBASE_VERIFY_ERROR] Token start:', idToken.substring(0, 20));
      throw new UnauthorizedError(`Firebase verification failed: ${error.message}`);
    }
  }

  async verifyOTP(phone: string, otp: string, deviceId: string, fingerprint: string): Promise<{ accessToken: string, refreshToken: string }> {
    const otpDoc = await OTPModel.findOne({ phone, otp, verified: false }).sort({ createdAt: -1 });

    if (!otpDoc || otpDoc.expiresAt < new Date()) {
      throw new UnauthorizedError('Invalid or expired OTP');
    }

    otpDoc.verified = true;
    await otpDoc.save();

    let user = await UserModel.findOne({ phone });
    if (!user) {
      user = await UserModel.create({ phone, role: ['BUYER'], deviceFingerprints: [fingerprint] });
    } else {
      if (!user.deviceFingerprints.includes(fingerprint)) {
        user.deviceFingerprints.push(fingerprint);
        await user.save();
      }
    }

    return this.issueTokens(user.id, deviceId);
  }

  async issueTokens(userId: string, deviceId: string): Promise<{ accessToken: string, refreshToken: string }> {
    const user = await UserModel.findById(userId);
    if (!user) throw new UnauthorizedError('User not found');

    const accessToken = jwt.sign({ 
      sub: userId, 
      deviceId,
      role: user.role,
      roles: user.role // Added for admin-web compatibility
    }, PRIVATE_KEY, {
      algorithm: 'RS256',
      expiresIn: '1h'
    });

    const refreshToken = crypto.randomBytes(40).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    await UserModel.findByIdAndUpdate(userId, {
      $push: {
        refreshTokens: { token: refreshToken, deviceId, expiresAt }
      }
    });

    return { accessToken, refreshToken };
  }

  async rotateRefreshToken(userId: string, oldRefreshToken: string, deviceId: string): Promise<{ accessToken: string, refreshToken: string }> {
    const user = await UserModel.findById(userId);
    if (!user) throw new UnauthorizedError();

    const tokenIndex = user.refreshTokens.findIndex(t => t.token === oldRefreshToken && t.deviceId === deviceId);
    if (tokenIndex === -1) {
      // Possible token reuse attack - invalidate all tokens for this user
      user.refreshTokens = [];
      await user.save();
      throw new UnauthorizedError('Refresh token invalid or reused');
    }

    const tokenDoc = user.refreshTokens[tokenIndex]!;
    if (tokenDoc.expiresAt < new Date()) {
      user.refreshTokens.splice(tokenIndex, 1);
      await user.save();
      throw new UnauthorizedError('Refresh token expired');
    }

    // Remove the old token
    user.refreshTokens.splice(tokenIndex, 1);
    await user.save();

    // Issue new ones
    return this.issueTokens(userId, deviceId);
  }
}
