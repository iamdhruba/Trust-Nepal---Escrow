import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { UserModel } from '../user/user.model.js';
import { AppError } from '../../errors/AppError.js';

export const submitKYC = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const bodySchema = z.object({
      fullName: z.string().min(3),
      dob: z.string().transform((val) => new Date(val)),
      idType: z.enum(['CITIZENSHIP', 'PASSPORT', 'DRIVING LICENSE', 'LICENSE']).transform(v => v === 'DRIVING LICENSE' ? 'LICENSE' : v),
      idNumber: z.string().min(3),
      documents: z.object({
        frontUrl: z.string().url(),
        backUrl: z.string().url(),
        selfieUrl: z.string().url(),
      })
    });

    const validatedData = bodySchema.parse(req.body);
    const userId = (req as any).user.sub; // From JWT middleware

    await UserModel.findByIdAndUpdate(userId, {
      kyc: {
        status: 'PENDING',
        submittedAt: new Date(),
        fullName: validatedData.fullName,
        dob: validatedData.dob,
        idType: validatedData.idType,
        idNumber: validatedData.idNumber,
        idFrontPath: validatedData.documents.frontUrl,
        idBackPath: validatedData.documents.backUrl,
        selfiePath: validatedData.documents.selfieUrl,
      }
    });

    res.status(202).json({ success: true, message: 'KYC submitted for review' });
  } catch (error) {
    next(error);
  }
};

export const getKYCStatus = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = (req as any).user.sub;
    const user = await UserModel.findById(userId).select('kyc');
    
    if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');

    res.status(200).json({ success: true, data: user.kyc });
  } catch (error) {
    next(error);
  }
};
