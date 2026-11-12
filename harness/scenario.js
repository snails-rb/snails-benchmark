import http from 'k6/http';

// The application-scenario driver: one primary-key read per iteration, with
// the id drawn from the seeded 1..10000 range. No checks in the hot path; a
// read that fails status is counted through http_req_failed.
const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:18091';

export const options = {
  scenarios: {
    item_read: {
      executor: 'constant-vus',
      vus: Number(__ENV.VUS || 8),
      duration: __ENV.DURATION || '20s',
      gracefulStop: '1s',
    },
  },
  discardResponseBodies: true,
  summaryTrendStats: ['avg', 'med', 'p(50)', 'p(95)', 'p(99)', 'max'],
  thresholds: {},
};

export default function () {
  const id = Math.floor(Math.random() * 10000) + 1;
  http.get(`${BASE_URL}/items/${id}`, { redirects: 0 });
}
