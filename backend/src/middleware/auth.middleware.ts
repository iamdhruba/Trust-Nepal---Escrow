import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { UnauthorizedError } from '../errors/AppError.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Helper to find keys directory
const findKeysDir = (startDir: string) => {
  let current = startDir;
  for (let i = 0; i < 5; i++) {
    const keysPath = path.join(current, 'keys');
    if (fs.existsSync(keysPath)) return keysPath;
    current = path.dirname(current);
  }
  return path.join(process.cwd(), 'keys');
};

const keysDir = findKeysDir(__dirname);

let PUBLIC_KEY = '';
try {
  if (process.env.JWT_PUBLIC_KEY) {
    PUBLIC_KEY = process.env.JWT_PUBLIC_KEY.replace(/\\n/g, '\n');
  } else {
    PUBLIC_KEY = fs.readFileSync(path.join(keysDir, 'public.pem'), 'utf8');
  }
} catch (e) {
  console.warn('[WARN] JWT_PUBLIC_KEY missing, auth middleware will deny all requests. Error:', e);
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
