import { check, sleep } from 'k6';
import http from 'k6/http';

export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp up
    { duration: '1m', target: 10 },    // Stay stable
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],   // 95% of requests under 500ms
    http_req_failed: ['rate<0.1'],      // Error rate under 10%
  },
};

export default function () {
  // Use environment variable or default to httpbin
  const baseUrl = __ENV.BASE_URL || 'https://httpbin.org';
  const res = http.get(`${baseUrl}/get`);
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has correct content-type': (r) => r.headers['Content-Type'].includes('application/json'),
  });
  
  // Simulate user think time
  sleep(1);
}