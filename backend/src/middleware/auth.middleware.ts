import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { UnauthorizedError } from '../errors/AppError.js';

let PUBLIC_KEY = '';
try {
  PUBLIC_KEY = process.env.JWT_PUBLIC_KEY?.replace(/\\n/g, '\n') || fs.readFileSync(path.join(process.cwd(), 'keys/public.pem'), 'utf8');
} catch (e) {
  console.warn('[WARN] JWT_PUBLIC_KEY missing, auth middleware will deny all requests.');
}


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
