import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

let commit = process.env.APP_REVISION || process.env.CI_COMMIT_SHA;
if (!commit) {
  try { commit = execFileSync('git', ['rev-parse', '--verify', 'HEAD'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim(); }
  catch { commit = 'local-development'; }
}
if (!/^(?:[0-9a-f]{7,64}|local-development)$/.test(commit)) {
  throw new Error('APP_REVISION must be a Git commit SHA or local-development');
}
writeFileSync(new URL('../public/version.json', import.meta.url), JSON.stringify({ version: '0.1.0', commit, builtAt: new Date().toISOString() }) + '\n');
