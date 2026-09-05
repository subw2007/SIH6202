const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const http = require('node:http');

// Set test env
process.env.NODE_ENV = 'test';
process.env.PORT = '5099';

const app = require('../server');

let server;
const BASE_URL = 'http://localhost:5099/api';

before((done) => {
  server = app.listen(5099, done);
});

after((done) => {
  server.close(done);
});

const makeRequest = (path, options = {}) => {
  return new Promise((resolve, reject) => {
    const url = new URL(`${BASE_URL}${path}`);
    const req = http.request(
      url,
      {
        method: options.method || 'GET',
        headers: {
          'Content-Type': 'application/json',
          ...(options.headers || {}),
        },
      },
      (res) => {
        let rawData = '';
        res.on('data', (chunk) => {
          rawData += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = rawData ? JSON.parse(rawData) : null;
            resolve({ statusCode: res.statusCode, data: parsed });
          } catch (e) {
            resolve({ statusCode: res.statusCode, raw: rawData });
          }
        });
      }
    );
    req.on('error', reject);
    if (options.body) {
      req.write(JSON.stringify(options.body));
    }
    req.end();
  });
};

describe('CivicPulse Backend API Tests', () => {
  test('GET /health returns 200 and online status', async () => {
    const res = await makeRequest('/health');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.data.status, 'ok');
    assert.strictEqual(res.data.service, 'civicpulse-backend');
  });

  test('GET /citizen-feed returns seeded citizen reports with exact keys', async () => {
    const res = await makeRequest('/citizen-feed');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.data.success, true);
    assert.ok(Array.isArray(res.data.data));
    assert.strictEqual(res.data.data.length, 5);

    const first = res.data.data[0];
    assert.strictEqual(first.id, 'rpt_001');
    assert.strictEqual(first.title, 'Deep pothole causing accidents');
    assert.strictEqual(first.location, 'Location');
    assert.strictEqual(first.upvoteCount, 14);
    assert.strictEqual(first.isVerified, true);
  });

  test('POST /reports creates a new report', async () => {
    const newReport = {
      title: 'Water logging near bus station',
      location: 'Bus Station Ward 3',
      has_image: true,
      image_source: 'camera',
      audio_path: 'mock://voice_test.m4a',
      audio_duration_ms: 12000,
    };
    const res = await makeRequest('/reports', {
      method: 'POST',
      body: newReport,
    });
    assert.strictEqual(res.statusCode, 201);
    assert.strictEqual(res.data.success, true);
    assert.strictEqual(res.data.data.title, 'Water logging near bus station');
    assert.strictEqual(res.data.data.audioDuration, '0:12');
  });

  test('POST /reports/:id/upvote increments upvote count', async () => {
    const res = await makeRequest('/reports/rpt_001/upvote', {
      method: 'POST',
    });
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.data.success, true);
    assert.strictEqual(res.data.data.upvoteCount, 15);
  });

  test('GET /solver-tasks returns tasks with metrics', async () => {
    const res = await makeRequest('/solver-tasks');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.data.success, true);
    assert.ok(Array.isArray(res.data.data));
    assert.strictEqual(res.data.metrics.total, 5);
    assert.strictEqual(res.data.metrics.highPriority, 2);
  });

  test('GET /solver-tasks?category=electricity filters properly', async () => {
    const res = await makeRequest('/solver-tasks?category=electricity');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.data.success, true);
    assert.strictEqual(res.data.data.length, 1);
    assert.strictEqual(res.data.data[0].id, 'streetlight-ward-8');
  });

  test('PATCH /solver-tasks/:id/status updates task status', async () => {
    const res = await makeRequest('/solver-tasks/pothole-sector-4/status', {
      method: 'PATCH',
      body: { status: 'inProgress' },
    });
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.data.success, true);
    assert.strictEqual(res.data.data.status, 'inProgress');
  });

  test('POST /solver-tasks/:id/join increments team member count', async () => {
    const res = await makeRequest('/solver-tasks/pothole-sector-4/join', {
      method: 'POST',
    });
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.data.success, true);
    assert.strictEqual(res.data.data.teamCount, 4);
  });
});
