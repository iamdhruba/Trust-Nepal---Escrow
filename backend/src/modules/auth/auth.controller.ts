import { Request, Response, NextFunction } from 'express';
import { AuthService } from './auth.service.js';
import { UserModel } from '../user/user.model.js';
import { z } from 'zod';

const authService = new AuthService();

export const sendOTP = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { phone } = z.object({
      phone: z.string().regex(/^9[678]\d{8}$/, 'Invalid Nepal phone number'),
    }).parse(req.body);
    await authService.sendOTP(phone);
    res.status(200).json({ success: true, message: 'OTP sent successfully' });
  } catch (error) {
    next(error);
  }
};

export const verifyOTP = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { phone, otp, deviceId, fingerprint } = z.object({
      phone: z.string(),
      otp: z.string().length(6),
      deviceId: z.string(),
      fingerprint: z.string(),
    }).parse(req.body);
    const tokens = await authService.verifyOTP(phone, otp, deviceId, fingerprint);
    res.status(200).json({ success: true, data: tokens });
  } catch (error) {
    next(error);
  }
};

export const verifyFirebase = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { idToken, deviceId, fingerprint } = z.object({
      idToken: z.string(),
      deviceId: z.string(),
      fingerprint: z.string(),
    }).parse(req.body);
    const tokens = await authService.verifyFirebaseToken(idToken, deviceId, fingerprint);
    res.status(200).json({ success: true, data: tokens });
  } catch (error) {
    next(error);
  }
};

export const refresh = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { userId, refreshToken, deviceId } = z.object({
      userId: z.string(),
      refreshToken: z.string(),
      deviceId: z.string(),
    }).parse(req.body);
    const tokens = await authService.rotateRefreshToken(userId, refreshToken, deviceId);
    res.status(200).json({ success: true, data: tokens });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { refreshToken, deviceId } = z.object({
      refreshToken: z.string(),
      deviceId: z.string(),
    }).parse(req.body);

    const userId = (req as any).user.sub;
    await UserModel.findByIdAndUpdate(userId, {
      $pull: { refreshTokens: { token: refreshToken, deviceId } },
    });

    res.status(200).json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    next(error);
  }
};
