import { Request, Response, NextFunction } from 'express';
import { UserModel } from './user.model.js';
import { AppError } from '../../errors/AppError.js';

export const getMe = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = await UserModel.findById(req.user.id);
    if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    
    res.json({ status: 'success', data: { user } });
  } catch (error) {
    next(error);
  }
};

export const updateMe = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { language, email } = req.body;
    
    const user = await UserModel.findByIdAndUpdate(
      req.user.id,
      { $set: { language, email } },
      { new: true, runValidators: true }
    );

    if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');

    res.json({ status: 'success', data: { user } });
  } catch (error) {
    next(error);
  }
};
export const lookupByPhone = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { phone } = req.params;
    const user = await UserModel.findOne({ phone }).select('kyc.fullName refreshTokens.deviceId');
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ 
      success: true, 
      data: { 
        fullName: user.kyc?.fullName || 'NepalTrust Verified User',
        isVerified: user.kyc?.status === 'APPROVED'
      } 
    });
  } catch (error) {
    next(error);
  }
};
