import { Request, Response, NextFunction } from 'express';
import { ForbiddenError } from '../errors/AppError.js';

export const rbac = (allowedRoles: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const userRoles = (req as any).user?.role || [];
    
    const hasRole = allowedRoles.some(role => userRoles.includes(role));
    
    if (!hasRole) {
      throw new ForbiddenError('You do not have permission to perform this action');
    }
    
    next();
  };
};
