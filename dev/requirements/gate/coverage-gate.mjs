#!/usr/bin/env node
// The bijection gate: every requirement leaf is claimed by exactly one case of
// a registered kind, or is a tracked gap in pending.json. Also the generator
// for the per-kind Swift manifests and the spec's golden gallery — Swift
// cannot discover case files at runtime, and a gallery nobody regenerates
// rots, so both are derived here and checked byte-for-byte.
//
// Usage: node coverage-gate.mjs [--write]
import { readFileSync, writeFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { KINDS, CASE_EXT, GOLDEN_EXT } from './kinds.mjs';

const GATE_DIR = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(GATE_DIR, '..');
const SPEC = join(ROOT, 'requirements.md');
const PENDING = join(GATE_DIR, 'pending.json');

// The framework's one shared parser: a leaf id is a backticked dotted number at
// the head of a line, optionally behind a list dash.
const ID_LINE = /^\s*(?:-\s+)?`(\d+(?:\.\d+)+)`/gm;
const CASE_FILE = new RegExp(`^([a-z0-9]+(?:-[a-z0-9]+)*)\\.(\\d+(?:\\.\\d+)+)\\.case\\.${CASE_EXT}$`);
const TBD = '⚠ TBD';
const GALLERY_MARK = '<!-- gallery:';

const write = process.argv.includes('--write');
const failures = [];
const fail = (msg) => failures.push(msg);

// ---------------------------------------------------------------- the spec
const spec = readFileSync(SPEC, 'utf8');
const specLines = spec.split('\n');
const ids = [...spec.matchAll(ID_LINE)].map((m) => m[1]);
const seenIds = new Set();
for (const id of ids) {
  if (seenIds.has(id)) fail(`spec: requirement id \`${id}\` appears twice`);
  seenIds.add(id);
}
// A leaf is an id no finer-numbered id descends from.
const leaves = ids.filter((id) => !ids.some((other) => other !== id && other.startsWith(`${id}.`)));
const leafSet = new Set(leaves);
const lineOfLeaf = new Map();
for (const [i, line] of specLines.entries()) {
  const m = /^\s*(?:-\s+)?`(\d+(?:\.\d+)+)`/.exec(line);
  if (m && leafSet.has(m[1])) lineOfLeaf.set(m[1], i);
}

// ------------------------------------------------------------- the pending
const pending = JSON.parse(readFileSync(PENDING, 'utf8'));
const pendingIds = new Set(pending.leaves.map((e) => e.id));
for (const entry of pending.leaves) {
  if (!leafSet.has(entry.id)) fail(`pending.json: \`${entry.id}\` is not a requirement leaf`);
  if (!entry.reason) fail(`pending.json: \`${entry.id}\` carries no reason`);
}
// The doc's loud marker and the allowlist say the same thing, in both directions.
for (const leaf of leaves) {
  const marked = (specLines[lineOfLeaf.get(leaf)] ?? '').includes(TBD);
  if (marked && !pendingIds.has(leaf)) fail(`spec: \`${leaf}\` is marked ${TBD} but is not in pending.json`);
  if (!marked && pendingIds.has(leaf)) fail(`spec: \`${leaf}\` is in pending.json but is not marked ${TBD}`);
}

// --------------------------------------------------------------- the kinds
const registered = new Map(KINDS.map((k) => [k.dir, k]));
for (const entry of readdirSync(ROOT, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  if (entry.name === 'gate' || entry.name === 'shared') continue;
  if (!registered.has(entry.name)) fail(`kinds: directory \`${entry.name}/\` is not in the kind registry`);
}

const claims = new Map(); // leaf id -> "kind/file"
for (const kind of KINDS) {
  const kindDir = join(ROOT, kind.dir);
  if (!existsSync(kindDir) || !statSync(kindDir).isDirectory()) {
    fail(`kinds: registered kind \`${kind.id}\` has no directory`);
    continue;
  }
  const casesDir = join(kindDir, 'cases');
  if (!existsSync(casesDir)) {
    fail(`kinds: \`${kind.id}\` has no cases/ directory`);
    continue;
  }
  const files = readdirSync(casesDir).sort();
  const cases = [];
  for (const file of files) {
    if (file.startsWith('.')) continue; // .gitkeep holds an as-yet-empty kind open
    if (file.endsWith(`.${GOLDEN_EXT}`)) continue; // goldens are checked below
    const m = CASE_FILE.exec(file);
    if (!m) {
      fail(`kinds: \`${kind.id}/cases/${file}\` is not named <slug>.<leaf-id>.case.${CASE_EXT}`);
      continue;
    }
    const [, slug, id] = m;
    if (!leafSet.has(id)) fail(`kinds: \`${kind.id}/cases/${file}\` claims \`${id}\`, which is not a requirement leaf`);
    else if (claims.has(id)) fail(`kinds: \`${id}\` is claimed twice — ${claims.get(id)} and ${kind.id}/cases/${file}`);
    else claims.set(id, `${kind.id}/cases/${file}`);
    if (pendingIds.has(id)) fail(`kinds: \`${id}\` has a case (${kind.id}/cases/${file}) and is also a tracked gap — remove it from pending.json`);
    cases.push({ slug, id, file, symbol: symbolFor(slug, id) });
  }

  // Goldens: only image kinds may hold them, and only beside their own case.
  const goldens = files.filter((f) => f.endsWith(`.${GOLDEN_EXT}`));
  if (!kind.images && goldens.length) {
    fail(`kinds: \`${kind.id}\` is not an image kind but holds ${goldens.join(', ')}`);
  } else {
    for (const golden of goldens) {
      const stem = golden.slice(0, -(GOLDEN_EXT.length + 1));
      if (!cases.some((c) => stem === `${c.slug}.${c.id}` || stem.startsWith(`${c.slug}.${c.id}.`))) {
        fail(`kinds: \`${kind.id}/cases/${golden}\` is a golden no case accounts for`);
      }
    }
    if (kind.images) {
      for (const c of cases) {
        if (!goldens.some((g) => g.startsWith(`${c.slug}.${c.id}`))) {
          fail(`kinds: \`${kind.id}/cases/${c.file}\` is an image-kind case with no committed golden`);
        }
      }
    }
  }

  // Swift discovers nothing at runtime, so the manifest is the registry the
  // runner reads — and it is generated, never hand-listed.
  const manifestPath = join(kindDir, 'Manifest.GENERATED.swift');
  const manifest = renderManifest(kind, cases);
  compare(manifestPath, manifest, `kinds: \`${kind.id}/Manifest.GENERATED.swift\` is out of sync with cases/ — run the gate with --write`);
}

// A kind nothing runs is a kind that proves nothing, so the runner must name
// every registered manifest.
const runner = readFileSync(join(ROOT, 'Runner.swift'), 'utf8');
for (const kind of KINDS) {
  const name = `${kind.id[0].toUpperCase()}${kind.id.slice(1)}Manifest.cases`;
  if (!runner.includes(name)) fail(`kinds: Runner.swift never executes \`${name}\``);
}

// Every leaf is claimed, or tracked as a gap — never neither, never both.
for (const leaf of leaves) {
  if (!claims.has(leaf) && !pendingIds.has(leaf)) {
    fail(`coverage: \`${leaf}\` is claimed by no case and is not a tracked gap`);
  }
}

// ------------------------------------------------------------- the gallery
// Under every image-kind leaf, the committed goldens embed as machine-managed
// lines; the doc is the owner's gallery of what the product actually renders.
const galleryLines = new Map();
for (const kind of KINDS.filter((k) => k.images)) {
  const casesDir = join(ROOT, kind.dir, 'cases');
  if (!existsSync(casesDir)) continue;
  for (const [id, claim] of claims) {
    if (!claim.startsWith(`${kind.id}/`)) continue;
    const stem = claim.slice(`${kind.id}/cases/`.length).replace(`.case.${CASE_EXT}`, '');
    const shots = readdirSync(casesDir).filter((f) => f.startsWith(stem) && f.endsWith(`.${GOLDEN_EXT}`)).sort();
    galleryLines.set(id, shots.map((s) => `${GALLERY_MARK}${id} --> ![${id}](${kind.dir}/cases/${s})`));
  }
}
const rebuilt = [];
for (const [i, line] of specLines.entries()) {
  if (line.startsWith(GALLERY_MARK)) continue; // regenerated below
  rebuilt.push(line);
  const m = /^\s*(?:-\s+)?`(\d+(?:\.\d+)+)`/.exec(line);
  if (m && galleryLines.has(m[1])) rebuilt.push(...galleryLines.get(m[1]));
}
compare(SPEC, `${rebuilt.join('\n').replace(/\n+$/, '')}\n`, 'gallery: requirements.md does not match the generator — run the gate with --write');

// ---------------------------------------------------------------- reporting
if (failures.length) {
  console.error(`Coverage gate: ${failures.length} failure(s)\n`);
  for (const f of failures) console.error(`  ✗ ${f}`);
  process.exit(1);
}
console.log(
  `Coverage gate: ${leaves.length} leaves — ${claims.size} claimed, ${pendingIds.size} tracked gaps.`,
);

function compare(path, expected, message) {
  const actual = existsSync(path) ? readFileSync(path, 'utf8') : null;
  if (actual === expected) return;
  if (write) {
    writeFileSync(path, expected);
    return;
  }
  fail(message);
}

// `stage-tap-queued` + `3.1` -> `stageTapQueued_3_1`, the symbol the case file
// declares and the manifest references.
function symbolFor(slug, id) {
  const camel = slug.split('-').map((p, i) => (i ? p[0].toUpperCase() + p.slice(1) : p)).join('');
  return `${camel}_${id.replaceAll('.', '_')}`;
}

function renderManifest(kind, cases) {
  const name = kind.id[0].toUpperCase() + kind.id.slice(1);
  const entries = cases.length
    ? `[\n${cases.map((c) => `        ${c.symbol},`).join('\n')}\n    ]`
    : '[]';
  return `// GENERATED by dev/requirements/gate/coverage-gate.mjs --write. Do not edit.
// Swift cannot discover case files at runtime, so this list is what the runner
// executes; the gate fails when it and cases/ disagree.

enum ${name}Manifest {
    static let cases: [RequirementCase] = ${entries}
}
`;
}
