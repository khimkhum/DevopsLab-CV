import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import https from 'node:https';
import net from 'node:net';

assert.ok(process.env.KUBERNETES_SERVICE_HOST,
  'Job must run inside Kubernetes');

for (const path of [
  '/var/run/docker.sock',
  '/var/run/secrets/kubernetes.io/serviceaccount/token',
  '/mnt/c',
  '/mnt/f',
]) {
  assert.equal(existsSync(path), false, `Unexpected path: ${path}`);
}

const status = readFileSync('/proc/self/status', 'utf8');
assert.match(status, /^NoNewPrivs:\s+1$/m);
assert.match(status, /^Seccomp:\s+2$/m);
console.log('PASS: job isolation settings');

const ca = readFileSync('/etc/ci-ca/ca.crt');

function checkHarbor(path, expectedStatus) {
  return new Promise((resolve, reject) => {
    const request = https.get({
      hostname: 'harbor.cv.test',
      port: 8443,
      path,
      ca,
      signal: AbortSignal.timeout(15000),
    }, response => {
      response.resume();
      response.on('error', reject);
      response.on('end', () => {
        try {
          assert.equal(response.statusCode, expectedStatus);
          console.log(`PASS: Harbor ${path} HTTP ${expectedStatus}`);
          resolve();
        } catch (error) {
          reject(error);
        }
      });
    });
    request.on('error', reject);
  });
}

await checkHarbor('/api/v2.0/ping', 200);
await checkHarbor('/v2/', 401);

const target = process.env.CI_DENY_TARGET;
assert.equal(net.isIP(target), 4, 'CI_DENY_TARGET must be IPv4');

const result = await new Promise(resolve => {
  const socket = net.createConnection({ host: target, port: 6443 });
  socket.setTimeout(3000);
  socket.once('connect', () => {
    socket.destroy();
    resolve({ connected: true });
  });
  socket.once('timeout', () => {
    socket.destroy();
    resolve({ connected: false, reason: 'ETIMEDOUT' });
  });
  socket.once('error', error => {
    socket.destroy();
    resolve({ connected: false, reason: error.code });
  });
});

assert.equal(result.connected, false,
  'Job unexpectedly reached runtime API');

assert.ok([
  'ETIMEDOUT', 'ECONNREFUSED', 'EHOSTUNREACH',
  'ENETUNREACH', 'EACCES',
].includes(result.reason), `Unexpected error: ${result.reason}`);

console.log(`PASS: runtime API TCP blocked (${result.reason})`);
console.log('PASS: runner probe completed');
