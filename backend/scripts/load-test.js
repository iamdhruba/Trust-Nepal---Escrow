import http from 'k6/http';
import { check, sleep } from 'k6';

/**
 * NepalTrust General API Benchmark
 */

export const options = {
  vus: 100,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<200'],
  },
};

export default function () {
  const res = http.get('http://localhost:3000/api/v1/auth/otp/send?phone=9841234567');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(0.1);
}
