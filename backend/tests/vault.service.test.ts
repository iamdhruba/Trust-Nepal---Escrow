import { describe, it, expect, beforeAll, afterAll, jest, beforeEach } from '@jest/globals';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { VaultService } from '../../src/modules/vault/vault.service.js';
import { VaultModel, VaultState } from '../../src/modules/vault/vault.model.js';
import { AuditLogModel } from '../../src/modules/vault/audit_log.model.js';

// Mocks
jest.mock('../../src/config/redis.js', () => ({
  redis: { incr: jest.fn(), expire: jest.fn(), del: jest.fn() },
  redlock: {
    acquire: jest.fn().mockResolvedValue({ release: jest.fn() }),
  },
}));
jest.mock('../../src/config/queue.js', () => ({
  invoiceQueue: { add: jest.fn().mockResolvedValue({}) },
  notificationQueue: { add: jest.fn().mockResolvedValue({}) },
  payoutQueue: { add: jest.fn().mockResolvedValue({}) },
  refundQueue: { add: jest.fn().mockResolvedValue({}) },
}));
jest.mock('../../src/config/secrets.js', () => ({
  getAuditSecret: jest.fn().mockResolvedValue('test-audit-secret'),
}));

let mongoServer: MongoMemoryServer;
let vaultService: VaultService;
const buyerId = new mongoose.Types.ObjectId().toString();
const sellerId = new mongoose.Types.ObjectId().toString();

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());
  vaultService = new VaultService();
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

beforeEach(async () => {
  await VaultModel.deleteMany({});
  await AuditLogModel.deleteMany({});
});

describe('VaultService — State Machine', () => {
  it('creates a vault in INITIATED state', async () => {
    const vault = await vaultService.createVault(
      { title: 'Test Vault', description: 'Test description', amount: 10000, sellerPhone: '9841234567' },
      buyerId
    );
    expect(vault.state).toBe(VaultState.INITIATED);
    expect(vault.platformFee).toBeCloseTo(150);
    expect(vault.netSellerAmount).toBeCloseTo(9850);
    expect(vault.currentHash).toBeTruthy();
  });

  it('transitions INITIATED → FUNDED on fund action', async () => {
    const vault = await vaultService.createVault(
      { title: 'Test Vault', description: 'desc', amount: 5000, sellerPhone: '9841111111' },
      buyerId
    );
    const funded = await vaultService.transition(vault.id, 'fund', 'system', 'SYSTEM', {});
    expect(funded.state).toBe(VaultState.FUNDED);
  });

  it('rejects invalid transition (INITIATED → SHIPPED)', async () => {
    const vault = await vaultService.createVault(
      { title: 'Test Vault', description: 'desc', amount: 5000, sellerPhone: '9841111111' },
      buyerId
    );
    await expect(
      vaultService.transition(vault.id, 'ship', sellerId, 'SELLER', {})
    ).rejects.toMatchObject({ code: 'INVALID_TRANSITION' });
  });

  it('creates audit log entry on each transition', async () => {
    const vault = await vaultService.createVault(
      { title: 'Audit Test', description: 'Testing audit', amount: 8000, sellerPhone: '9849999999' },
      buyerId
    );
    await vaultService.transition(vault.id, 'fund', 'system', 'SYSTEM');
    const logs = await vaultService.getAuditLogs(vault.id);
    expect(logs.length).toBe(1);
    expect(logs[0]!.action).toBe('fund');
    expect(logs[0]!.hash).toBeTruthy();
    expect(logs[0]!.prevHash).toBeTruthy();
  });

  it('enforces hash chain integrity', async () => {
    const vault = await vaultService.createVault(
      { title: 'Hash Test', description: 'Testing hash chain', amount: 12000, sellerPhone: '9841234560' },
      buyerId
    );
    const funded = await vaultService.transition(vault.id, 'fund', 'system', 'SYSTEM');
    const logs = await vaultService.getAuditLogs(vault.id);
    expect(logs[0]!.prevHash).toBe(vault.currentHash);
    expect(funded.currentHash).toBe(logs[0]!.hash);
  });
});
