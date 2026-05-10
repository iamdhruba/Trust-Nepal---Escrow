import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { UnauthorizedError } from '../errors/AppError.js';

const PUBLIC_KEY = fs.readFileSync(path.join(process.cwd(), 'keys/public.pem'), 'utf8');

export const authenticate = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('Authentication token required');
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token!, PUBLIC_KEY, { algorithms: ['RS256'] });
    (req as any).user = payload;
    next();
  } catch (err) {
    throw new UnauthorizedError('Invalid or expired token');
  }
};
