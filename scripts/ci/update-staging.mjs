import assert from 'node:assert/strict';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const api = 'https://gitlab.com/api/v4';
const sourceProject = '88096308';
const gitopsProject = '88155690';
const branch = 'staging';
const filePath = 'overlays/staging/kustomization.yaml';

async function main() {
  const env = process.env;

  for (const key of [
    'CI_PROJECT_DIR',
    'CI_COMMIT_SHA',
    'CI_PIPELINE_URL',
    'CI_JOB_TOKEN',
    'GITOPS_API_TOKEN',
  ]) {
    assert.ok(env[key], `Missing ${key}`);
  }

  assert.equal(env.CI_PROJECT_ID, sourceProject);
  assert.equal(env.CI_COMMIT_BRANCH, 'main');
  assert.equal(env.CI_DEFAULT_BRANCH, 'main');
  assert.equal(env.CI_COMMIT_REF_PROTECTED, 'true');
  assert.equal(
    Boolean(env.HARBOR_DOCKER_AUTH),
    false,
    'Harbor credential must not enter the GitOps job',
  );
  assert.match(env.CI_COMMIT_SHA, /^[0-9a-f]{40}$/);

  let token;

  try {
    token = readFileSync(env.GITOPS_API_TOKEN, 'utf8').trim();
  } catch {
    throw new Error(
      'GITOPS_API_TOKEN must be a readable GitLab File variable',
    );
  }

  assert.ok(
    token.length >= 8 && !/\s/.test(token),
    'Invalid GitOps token file',
  );

  function approved(target, repository) {
    const directory = join(
      env.CI_PROJECT_DIR,
      '.artifacts/ci/security',
      target,
    );

    const image = readFileSync(
      join(directory, 'approved-image.txt'),
      'utf8',
    ).trim();

    const metadata = JSON.parse(
      readFileSync(
        join(directory, 'build-metadata.json'),
        'utf8',
      ),
    );

    assert.equal(metadata.target, target);
    assert.equal(metadata.commit, env.CI_COMMIT_SHA);
    assert.equal(metadata.pipeline_url, env.CI_PIPELINE_URL);
    assert.match(metadata.digest, /^sha256:[0-9a-f]{64}$/);
    assert.equal(image, `${repository}@${metadata.digest}`);
    assert.equal(metadata.pinned_image, image);

    return { image, digest: metadata.digest };
  }

  const runtime = approved(
    'runtime',
    'harbor.cv.test:8443/cv/portfolio',
  );

  const gateway = approved(
    'gateway',
    'harbor.cv.test:8443/cv/gateway',
  );

  async function request(path, headers, method = 'GET', body) {
    const response = await fetch(api + path, {
      method,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: body === undefined
        ? undefined
        : JSON.stringify(body),
      redirect: 'error',
      signal: AbortSignal.timeout(20000),
    });

    assert.equal(
      response.status,
      method === 'GET' ? 200 : 201,
      `GitLab ${method} ${path}: HTTP ${response.status}`,
    );

    return response.json();
  }

  async function assertCurrentSource() {
    const branches = await request(
      `/projects/${sourceProject}/repository/branches?search=main&per_page=100`,
      { 'JOB-TOKEN': env.CI_JOB_TOKEN },
    );

    const sourceMain = branches.find(
      item => item.name === 'main',
    );

    assert.equal(
      sourceMain?.commit?.id,
      env.CI_COMMIT_SHA,
      'Source main moved; use the latest pipeline',
    );
  }

  await assertCurrentSource();

  const headers = { 'PRIVATE-TOKEN': token };
  const project = await request(
    `/projects/${gitopsProject}`,
    headers,
  );

  const permissions = project.permissions || {};
  const level = Math.max(
    permissions.project_access?.access_level || 0,
    permissions.group_access?.access_level || 0,
  );

  assert.equal(
    level,
    30,
    'GitOps bot must have Developer access',
  );

  const staging = await request(
    `/projects/${gitopsProject}/repository/branches/staging`,
    headers,
  );

  const protectedMain = await request(
    `/projects/${gitopsProject}/repository/branches/main`,
    headers,
  );

  assert.equal(staging.can_push, true);
  assert.equal(protectedMain.protected, true);
  assert.equal(protectedMain.can_push, false);
  assert.equal(protectedMain.developers_can_merge, false);

  const file = await request(
    `/projects/${gitopsProject}/repository/files/${encodeURIComponent(filePath)}?ref=${branch}`,
    headers,
  );

  assert.equal(file.file_path, filePath);
  assert.equal(file.encoding, 'base64');
  assert.match(file.last_commit_id, /^[0-9a-f]{40}$/);
  assert.match(file.commit_id, /^[0-9a-f]{40}$/);

  const content = Buffer.from(
    file.content,
    'base64',
  ).toString('utf8');

  assert.match(content, /^namespace: cv-staging\r?$/m);
  assert.equal(
    (content.match(/^images:\r?$/gm) || []).length,
    1,
  );

  const pattern = /(^images:\r?\n  - name: harbor\.cv\.test:8443\/cv\/portfolio\r?\n    digest: )(sha256:[0-9a-f]{64})(?=\r?\n|$)/gm;

  assert.equal(
    [...content.matchAll(pattern)].length,
    1,
    'Unexpected image block; review GitOps YAML manually',
  );

  const updated = content.replace(
    pattern,
    (_match, prefix) => prefix + runtime.digest,
  );

  await assertCurrentSource();

  const changed = content !== updated;
  let revision = file.commit_id;

  if (changed) {
    const commit = await request(
      `/projects/${gitopsProject}/repository/commits`,
      headers,
      'POST',
      {
        branch,
        commit_message:
          `deploy(staging): CV ${env.CI_COMMIT_SHA.slice(0, 8)}`,
        actions: [
          {
            action: 'update',
            file_path: filePath,
            content: updated,
            last_commit_id: file.last_commit_id,
          },
        ],
      },
    );

    revision = commit.id;
  }

  assert.match(revision, /^[0-9a-f]{40}$/);

  const result = {
    source_commit: env.CI_COMMIT_SHA,
    pipeline_url: env.CI_PIPELINE_URL,
    runtime_image: runtime.image,
    gateway_image: gateway.image,
    gitops_project: gitopsProject,
    gitops_branch: branch,
    gitops_revision: revision,
    file_path: filePath,
    changed,
  };

  const output = join(
    env.CI_PROJECT_DIR,
    '.artifacts/ci/gitops',
  );

  mkdirSync(output, { recursive: true });

  writeFileSync(
    join(output, 'staging-update.json'),
    JSON.stringify(result, null, 2) + '\n',
  );

  console.log(
    `PASS: staging GitOps handoff; changed=${changed}; revision=${revision}`,
  );
}

main().catch(error => {
  console.error(`FAIL: ${error.message}`);
  process.exitCode = 1;
});
