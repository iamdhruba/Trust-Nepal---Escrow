import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { UnauthorizedError } from '../errors/AppError.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

let PUBLIC_KEY = '';
try {
  if (process.env.JWT_PUBLIC_KEY) {
    PUBLIC_KEY = process.env.JWT_PUBLIC_KEY.replace(/\\n/g, '\n');
  } else {
    PUBLIC_KEY = fs.readFileSync(path.join(__dirname, '../../keys/public.pem'), 'utf8');
  }
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
