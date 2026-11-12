import http from 'k6/http';

// Minimal GET /up driver: no redirects to follow, no bodies kept, no checks in
// the hot path (a check allocates and skews the numbers). One scenario with a
// fixed VU count, which is what `bin/bench` sweeps to find the saturation knee.
export const options = {
  scenarios: {
    up: {
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
  http.get(__ENV.URL || 'http://127.0.0.1:18080/up', { redirects: 0 });
}
