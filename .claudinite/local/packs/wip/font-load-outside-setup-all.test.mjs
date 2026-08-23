// See-it-fail fixture for the wip pack's declared check
// "flutter/font-load-outside-setup-all" (declared-checks.json): fires when
// loadProductFonts() is invoked inside a test/testWidgets body, stays quiet on
// the documented setUpAll forms. Runs the real check engine against throwaway
// git fixtures — `node --test` needs no project-level test runner.
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
const RULE_ID = 'flutter/font-load-outside-setup-all';

function findingsFor(files) {
  const root = mkdtempSync(join(tmpdir(), 'wip-font-load-check-'));
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
    assert.ok(rule, `${RULE_ID} must be declared in the wip pack`);
    return runRule(rule, ctx);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test('fires when loadProductFonts() is invoked inside a testWidgets body', () => {
  const findings = findingsFor({
    'test/bad_test.dart': `
void main() {
  testWidgets('bad', (tester) async {
    loadProductFonts();
  });
}
`,
  });
  assert.equal(findings.length, 1);
  assert.equal(findings[0].line, 4);
});

test('stays quiet on the documented setUpAll(loadProductFonts) tear-off', () => {
  const findings = findingsFor({
    'test/good_tear_off_test.dart': `
void main() {
  setUpAll(loadProductFonts);

  testWidgets('good', (tester) async {
    expect(1, 1);
  });
}
`,
  });
  assert.equal(findings.length, 0);
});

test('stays quiet on loadProductFonts() invoked inside setUpAll itself', () => {
  const findings = findingsFor({
    'test/good_wrapped_test.dart': `
void main() {
  setUpAll(() async {
    await loadProductFonts();
  });
}
`,
  });
  assert.equal(findings.length, 0);
});
