import axios from 'axios';
import pino from 'pino';

const logger = pino({ name: 'idempotency-test' });

/**
 * NepalTrust Idempotency Test
 * Requirement: hhh.md line 594 (Idempotency tested under 100 concurrent requests)
 */

async function runIdempotencyTest() {
  const BASE_URL = 'http://localhost:3000/api/v1';
  const idempotencyKey = `test-key-${Date.now()}`;
  const vaultData = {
    title: 'Idempotency Test Item',
    amount: 1000,
    sellerPhone: '9800000000'
  };

  logger.info({ idempotencyKey }, 'Starting concurrent idempotency test (100 requests)...');

  const requests = Array.from({ length: 100 }).map((_, i) => 
    axios.post(`${BASE_URL}/vaults`, vaultData, {
      headers: {
        'Content-Type': 'application/json',
        'Idempotency-Key': idempotencyKey,
        'Authorization': 'Bearer YOUR_TEST_TOKEN' // In real test, fetch a token first
      },
      validateStatus: () => true // Don't throw on error
    })
  );

  const results = await Promise.all(requests);
  
  const successCount = results.filter(r => r.status === 201).length;
  const conflictCount = results.filter(r => r.status === 409).length;
  const errorCount = results.filter(r => r.status >= 500).length;

  logger.info({
    successCount,
    conflictCount,
    errorCount
  }, 'Test complete.');

  if (successCount === 1 && conflictCount === 99) {
    logger.info('SUCCESS: Idempotency strictly enforced.');
  } else {
    logger.error('FAILURE: Multiple successes or unexpected error codes found.');
  }
}

runIdempotencyTest();
