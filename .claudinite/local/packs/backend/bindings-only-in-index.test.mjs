// See-it-fail fixture for the backend pack's declared check
// "backend/bindings-only-in-index" (declared-checks.json): fires when a file
// under backend/src/ other than index.js touches a Cloudflare binding
// (env.*) or imports cloudflare:workers, stays quiet on index.js itself and
// on plain rule modules with no binding access. Runs the real check engine
// against throwaway git fixtures — `node --test` needs no project-level test
// runner.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';

import { buildContext } from '../../../shared/engine/checks/helpers/repo-context.mjs';
import { loadDeclaredChecks } from '../../../shared/engine/checks/helpers/pattern-rules.mjs';
import { runRule } from '../../../shared/engine/checks/helpers/work.mjs';

const PACK_DIR = dirname(new URL(import.meta.url).pathname);
const RULE_ID = 'backend/bindings-only-in-index';

function findingsFor(files) {
  const root = mkdtempSync(join(tmpdir(), 'backend-bindings-check-'));
  try {
    execFileSync('git', ['init', '--quiet'], { cwd: root });
    for (const [path, content] of Object.entries(files)) {
      const full = join(root, path);
      mkdirSync(dirname(full), { recursive: true });
      writeFileSync(full, content);
    }
    execFileSync('git', ['add', '-A'], { cwd: root });
    const ctx = buildContext({ root, mode: 'all' });
    const rule = loadDeclaredChecks(PACK_DIR).find((r) => r.id === RULE_ID);
    assert.ok(rule, `${RULE_ID} must be declared in the backend pack`);
    return runRule(rule, ctx);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test('fires when a src module outside index.js reads an env binding', () => {
  const findings = findingsFor({
    'backend/src/pipeline/segment.js': `
export function segment(showId) {
  return env.DB.prepare('select 1').run();
}
`,
  });
  assert.equal(findings.length, 1);
  assert.equal(findings[0].line, 3);
});

test('fires when a src module outside index.js imports cloudflare:workers', () => {
  const findings = findingsFor({
    'backend/src/pipeline/process-show.js': `
import { WorkflowEntrypoint } from 'cloudflare:workers';
export class X extends WorkflowEntrypoint {}
`,
  });
  assert.equal(findings.length, 1);
  assert.equal(findings[0].line, 2);
});

test('stays quiet on index.js itself, which is where bindings turn into ports', () => {
  const findings = findingsFor({
    'backend/src/index.js': `
import { WorkflowEntrypoint } from 'cloudflare:workers';
export default {
  async fetch(request, env) {
    return env.DB.prepare('select 1').run();
  },
};
`,
  });
  assert.equal(findings.length, 0);
});

test('stays quiet on a plain rule module with no binding access', () => {
  const findings = findingsFor({
    'backend/src/chunking/plan.js': `
export function planChunks(durationSeconds, chunkSeconds) {
  return Math.ceil(durationSeconds / chunkSeconds);
}
`,
  });
  assert.equal(findings.length, 0);
});
