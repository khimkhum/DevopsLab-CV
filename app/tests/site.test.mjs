import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const dist = new URL('../dist/', import.meta.url);
const html = readFileSync(new URL('index.html', dist), 'utf8');

test('release contains the actual CV identity and contact actions', () => {
  assert.match(html, /Lê Văn Khiêm/);
  assert.match(html, /mailto:levankhiem0000@gmail\.com/);
  assert.match(html, /https:\/\/github\.com\/khimkhum\/vprofile-full/);
  assert.match(html, /https:\/\/github\.com\/khimkhum\/devops-demo-app/);
});

test('all same-page navigation targets exist', () => {
  const ids = new Set([...html.matchAll(/\bid="([^"]+)"/g)].map(match => match[1]));
  for (const [, id] of html.matchAll(/href="#([^"]+)"/g)) assert.ok(ids.has(id), `Missing anchor: ${id}`);
});

test('download and health resources are real build artifacts', () => {
  const pdf = readFileSync(new URL('cv/le-van-khiem-devops.pdf', dist));
  assert.equal(pdf.subarray(0, 5).toString(), '%PDF-');
  assert.equal(readFileSync(new URL('healthz', dist), 'utf8').trim(), 'ok');
  assert.ok(existsSync(new URL('portrait.jpg', dist)));
});

test('all root-relative HTML assets resolve inside dist', () => {
  for (const [, pathname] of html.matchAll(/(?:src|href)="(\/[^"#?]*)"/g)) {
    const target = new URL('.' + pathname, dist);
    assert.ok(existsSync(target) || existsSync(join(target.pathname, 'index.html')), `Missing asset: ${pathname}`);
  }
});

test('release metadata exposes revision, never environment secrets', () => {
  const version = JSON.parse(readFileSync(new URL('version.json', dist), 'utf8'));
  assert.deepEqual(Object.keys(version).sort(), ['builtAt', 'commit', 'version']);
  assert.match(version.commit, /^(?:[0-9a-f]{7,64}|local-development)$/);
  assert.ok(!Number.isNaN(Date.parse(version.builtAt)));
  assert.ok(!/<script\b/i.test(html), 'The portfolio should not require browser JavaScript');
});
