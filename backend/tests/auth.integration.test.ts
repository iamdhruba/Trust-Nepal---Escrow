import { describe, it, expect, beforeAll, afterAll, jest } from '@jest/globals';
import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import express from 'express';
import { AuthService } from '../../src/modules/auth/auth.service.js';
import { OTPModel } from '../../src/modules/auth/otp.model.js';
import { UserModel } from '../../src/modules/user/user.model.js';
import { errorHandler } from '../../src/middleware/errorHandler.js';
import authRoutes from '../../src/modules/auth/auth.routes.js';

// Mock Redis
jest.mock('../../src/config/redis.js', () => ({
  redis: { incr: jest.fn().mockResolvedValue(1), expire: jest.fn(), del: jest.fn() },
  redlock: { acquire: jest.fn().mockResolvedValue({ release: jest.fn() }) },
}));

let mongoServer: MongoMemoryServer;
let app: express.Application;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  app = express();
  app.use(express.json());
  app.use('/api/v1/auth', authRoutes);
  app.use(errorHandler);
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('Auth — OTP Flow', () => {
  const phone = '9841234567';

  it('POST /otp/send — returns 200', async () => {
    const res = await request(app)
      .post('/api/v1/auth/otp/send')
      .send({ phone });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('POST /otp/send — rejects invalid phone', async () => {
    const res = await request(app)
      .post('/api/v1/auth/otp/send')
      .send({ phone: '1234' });
    expect(res.status).toBe(400);
  });

  it('POST /otp/verify — rejects wrong OTP', async () => {
    const res = await request(app)
      .post('/api/v1/auth/otp/verify')
      .send({ phone, otp: '000000', deviceId: 'dev1', fingerprint: 'fp1' });
    expect(res.status).toBe(401);
  });

  it('POST /otp/verify — succeeds with valid OTP', async () => {
    const otp = '123456';
    await OTPModel.create({ phone, otp, expiresAt: new Date(Date.now() + 60000), verified: false });

    const res = await request(app)
      .post('/api/v1/auth/otp/verify')
      .send({ phone, otp, deviceId: 'dev1', fingerprint: 'fp1' });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveProperty('accessToken');
    expect(res.body.data).toHaveProperty('refreshToken');
  });
});
