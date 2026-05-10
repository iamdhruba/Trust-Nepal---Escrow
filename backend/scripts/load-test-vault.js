import http from 'k6/http';
import { check, sleep, group } from 'k6';

/**
 * NepalTrust Stress Test - 1000 RPS Target
 * 
 * Requirement: hhh.md line 502 (Load test: 1000 RPS sustained)
 */

export const options = {
  stages: [
    { duration: '2m', target: 200 }, // Ramp-up to 200 virtual users
    { duration: '5m', target: 200 }, // Sustain load
    { duration: '1m', target: 0 },   // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(99)<800'], // 99% of requests must be under 800ms (Requirement: hhh.md line 590)
    http_req_failed: ['rate<0.001'],  // Error rate < 0.1%
  },
};

const BASE_URL = 'http://localhost:3000/api/v1';

export default function () {
  const phone = `984${Math.floor(Math.random() * 9000000 + 1000000)}`;
  const deviceId = `device-${__VU}-${__ITER}`;
  
  // 1. Auth Flow (RPS contribution: ~15%)
  group('Auth', () => {
    const otpRes = http.post(`${BASE_URL}/auth/otp/send`, JSON.stringify({ phone }), {
      headers: { 'Content-Type': 'application/json' },
    });
    check(otpRes, { 'otp ok': (r) => r.status === 200 || r.status === 201 });
  });

  // 2. High Frequency Vault Polling (RPS contribution: ~70%)
  // Simulates mobile apps waiting for state updates via polling (fallback to Socket.io)
  group('Polling', () => {
    for (let i = 0; i < 5; i++) {
      const getRes = http.get(`${BASE_URL}/vaults`, {
        headers: { 'X-Request-Id': `poll-${__VU}-${__ITER}-${i}` }
      });
      check(getRes, { 'list ok': (r) => r.status === 200 });
      sleep(0.5); // Fast polling
    }
  group('Create', () => {
     const createRes = http.post(`${BASE_URL}/vaults`, JSON.stringify({
        title: 'Load Test Item',
        amount: 1000,
        sellerPhone: '9800000000'
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
      check(createRes, { 'create ok': (r) => r.status === 201 });
    });
  });

  sleep(1); // Small pause before next iteration
}
