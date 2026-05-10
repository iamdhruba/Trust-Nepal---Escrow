import { Request, Response, NextFunction } from 'express';
import { UserModel } from '../user/user.model.js';
import { AppError } from '../../errors/AppError.js';
import { z } from 'zod';

export const reviewKYC = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { userId } = req.params;
    const { status, reason } = z.object({
      status: z.enum(['APPROVED', 'REJECTED', 'RESUBMIT']),
      reason: z.string().optional(),
    }).parse(req.body);

    const adminId = (req as any).user.sub;

    const user = await UserModel.findById(userId);
    if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');

    user.kyc.status = status;
    user.kyc.reviewedAt = new Date();
    user.kyc.reviewedBy = adminId;
    if (reason) user.kyc.rejectionReason = reason;

    if (status === 'APPROVED') {
      if (!user.role.includes('VERIFIED_USER')) {
        user.role.push('VERIFIED_USER');
      }
    }

    await user.save();

    res.status(200).json({ success: true, message: `KYC ${status}` });
  } catch (error) {
    next(error);
  }
};
