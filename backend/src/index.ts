import 'dotenv/config';
import mongoose from 'mongoose';
import { createServer } from 'http';
import pino from 'pino';
import helmet from 'helmet';
import cors from 'cors';
import express from 'express';
import crypto from 'crypto';
import path from 'path';
import fs from 'fs';
import * as Sentry from '@sentry/node';

import authRoutes from './modules/auth/auth.routes.js';
import kycRoutes from './modules/kyc/kyc.routes.js';
import vaultRoutes from './modules/vault/vault.routes.js';
import paymentRoutes from './modules/payment/payment.routes.js';
import paymentInitiateRoutes from './modules/payment/payment.initiate.routes.js';
import userRoutes from './modules/user/user.routes.js';
import notificationRoutes from './modules/notifications/notification.routes.js';
import disputeRoutes from './modules/dispute/dispute.routes.js';
import adminRoutes from './modules/admin/admin.routes.js';
import uploadsRoutes from './modules/uploads/uploads.routes.js';
import invoicesRoutes from './modules/invoices/invoices.routes.js';

import { setupSocket } from './config/socket.js';
import { metricsMiddleware } from './config/metrics.js';
import { rateLimiter, authRateLimiter } from './middleware/rateLimiter.js';
import { errorHandler } from './middleware/errorHandler.js';
import { initializeFirebase } from './config/firebase.js';
import { initAgenda } from './config/agenda.js';
import { startWorkers } from './workers/index.js';

const logger = pino();
const app = express();
const httpServer = createServer(app);
const io = setupSocket(httpServer);
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://admin:password123@localhost:27017/trustnepal?authSource=admin';

Sentry.init({ dsn: process.env.SENTRY_DSN });

app.use(metricsMiddleware as any);
const allowedOrigins = process.env.NODE_ENV === 'production' 
  ? ['https://app.trustnepal.com', 'https://admin.trustnepal.com', 'http://localhost:5173'] 
  : '*';
app.use(cors({ origin: allowedOrigins }));
app.use(rateLimiter);
app.use(helmet());
app.use(express.json({ limit: '10mb' }));

// Static files (for local uploads)
const UPLOADS_DIR = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}
app.use('/uploads', express.static(UPLOADS_DIR));

// Observability middleware
app.use((req, res, next) => {
  const start = Date.now();
  const requestId = req.headers['x-request-id'] || crypto.randomUUID();
  req.headers['x-request-id'] = requestId as string;
  res.setHeader('x-request-id', requestId);
  res.on('finish', () => {
    logger.info({ method: req.method, url: req.url, status: res.statusCode, duration: Date.now() - start, requestId });
  });
  next();
});

// Routes
app.use('/api/v1/auth', authRateLimiter, authRoutes);
app.use('/api/v1/kycs', kycRoutes);
app.use('/api/v1/vaults', vaultRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/payment', paymentInitiateRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/disputes', disputeRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/uploads', uploadsRoutes);
app.use('/api/v1/invoices', invoicesRoutes);

// Health check
app.get('/health', (_req, res) => res.json({ status: 'ok', timestamp: new Date() }));

// Error handler (must be last)
app.use(errorHandler);

const start = async () => {
  try {
    await mongoose.connect(MONGO_URI);
    logger.info('Connected to MongoDB');
    await initializeFirebase();
    startWorkers();
    await initAgenda();
    httpServer.listen(PORT, () => logger.info(`Server running on port ${PORT}`));
  } catch (error) {
    logger.error(error, 'Failed to start server');
    process.exit(1);
  }
};

start();
