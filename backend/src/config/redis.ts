import Redis from 'ioredis';
// @ts-expect-error redlock typings issue
import Redlock from 'redlock';

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  maxRetriesPerRequest: null,
});

const redlock = new Redlock(
  [redis],
  {
    driftFactor: 0.01,
    retryCount: 10,
    retryDelay: 200,
    retryJitter: 200,
    automaticExtensionThreshold: 500,
  }
);

export { redis, redlock };
