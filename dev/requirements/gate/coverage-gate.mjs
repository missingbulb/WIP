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
const GALLERY_OPEN = (id) => `<!-- req-gallery:${id} -->`;
const GALLERY_CLOSE = (id) => `<!-- /req-gallery:${id} -->`;
const GALLERY_ANY = /^\s*<!-- \/?req-gallery:/;
// A whole-screen render is a page-tall image; inlining it under its leaf pushes
// the numbered spine off the screen. Those blocks collect in one section at the
// foot of the doc instead, and the leaf keeps a generated link to it.
const FULL_OPEN = '<!-- req-gallery-full -->';
const FULL_CLOSE = '<!-- /req-gallery-full -->';
const FULL_ANCHOR = '#full-screen-renders';

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
const wholeScreenIds = new Set(); // leaves whose picture is the whole screen
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
    if (file.endsWith('.captions.json')) continue; // a saga's captions, generated beside its frames
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
        if (kind.scoped) {
          // A picture of the whole screen where the leaf is about one element
          // is the failure mode this kind exists to avoid, and it is invisible
          // in a green run — the case still passes, it just proves less. So the
          // capture's scope is declared, one way or the other.
          const source = readFileSync(join(casesDir, c.file), 'utf8');
          // The same declaration that justifies the scope also places the
          // picture: whole-screen renders gallery at the foot of the doc.
          if (/\/\/ whole-screen: \S/.test(source)) wholeScreenIds.add(c.id);
          if (!/\bregion: \./.test(source) && !/\/\/ whole-screen: \S/.test(source)) {
            fail(
              `kinds: \`${kind.id}/cases/${c.file}\` names no region — crop to the element the leaf is about, ` +
              'or say why the whole screen is the proof in a `// whole-screen: <reason>` comment',
            );
          }
        }
        if (!kind.frames) continue;
        // A story with no caption is a slideshow: the frames only narrate
        // anything while the captions stay in step with them.
        const captionsPath = join(casesDir, `${c.slug}.${c.id}.captions.json`);
        if (!existsSync(captionsPath)) {
          fail(`kinds: \`${kind.id}/cases/${c.file}\` has no committed captions`);
          continue;
        }
        const captions = JSON.parse(readFileSync(captionsPath, 'utf8'));
        const frames = goldens.filter((g) => g.startsWith(`${c.slug}.${c.id}.step-`));
        if (captions.length !== frames.length) {
          fail(`kinds: \`${c.slug}.${c.id}\` has ${frames.length} frames and ${captions.length} captions`);
        }
      }
    }
  }

  // Swift discovers nothing at runtime, so the manifest is the registry the
  // runner reads — and it is generated, never hand-listed.
  // One module compiles every kind's manifest, so the basenames must differ.
  const manifestName = `${kindName(kind)}Manifest.GENERATED.swift`;
  compare(
    join(kindDir, manifestName),
    renderManifest(kind, cases),
    `kinds: \`${kind.dir}/${manifestName}\` is out of sync with cases/ — run the gate with --write`,
  );
}

// A kind nothing runs is a kind that proves nothing, so the runner must name
// every registered manifest.
const runner = readFileSync(join(ROOT, 'Runner.swift'), 'utf8');
for (const kind of KINDS) {
  const name = `${kindName(kind)}Manifest.cases`;
  if (!runner.includes(name)) fail(`kinds: Runner.swift never executes \`${name}\``);
}

// Every leaf is claimed, or tracked as a gap — never neither, never both.
for (const leaf of leaves) {
  if (!claims.has(leaf) && !pendingIds.has(leaf)) {
    fail(`coverage: \`${leaf}\` is claimed by no case and is not a tracked gap`);
  }
}

// ------------------------------------------------------------- the gallery
// The picture under a leaf IS its expected rendering, so the spec doubles as
// the gallery of what the product actually shows: approving the spec is
// approving the pixels. Everything between a leaf's gallery markers is written
// here and nowhere else.
const galleryBlocks = new Map();
const fullBlocks = new Map();
for (const kind of KINDS.filter((k) => k.images)) {
  const casesDir = join(ROOT, kind.dir, 'cases');
  if (!existsSync(casesDir)) continue;
  const files = readdirSync(casesDir).sort();
  for (const [id, claim] of claims) {
    if (!claim.startsWith(`${kind.id}/`)) continue;
    const stem = claim.slice(`${kind.id}/cases/`.length).replace(`.case.${CASE_EXT}`, '');
    const shots = files.filter((f) => f.startsWith(`${stem}.`) && f.endsWith(`.${GOLDEN_EXT}`)).sort();
    const lines = [`  ${GALLERY_OPEN(id)}`];
    if (kind.frames) {
      const captionsPath = join(casesDir, `${stem}.captions.json`);
      const captions = existsSync(captionsPath) ? JSON.parse(readFileSync(captionsPath, 'utf8')) : [];
      shots.forEach((shot, index) => {
        lines.push(`  ${index + 1}. **${captions[index] ?? ''}**`, '');
        lines.push(`     ![${stem} step ${index + 1}](${kind.dir}/cases/${shot})`, '');
      });
      if (lines.at(-1) === '') lines.pop();
    } else {
      for (const shot of shots) lines.push(`  ![${stem}](${kind.dir}/cases/${shot})`);
    }
    lines.push(`  ${GALLERY_CLOSE(id)}`);
    if (wholeScreenIds.has(id)) {
      // The leaf keeps a marker so every image-kind leaf still carries a
      // generated block; what it carries is the way to the picture.
      galleryBlocks.set(id, [
        `  ${GALLERY_OPEN(id)}`,
        `  [Full-screen render →](${FULL_ANCHOR})`,
        `  ${GALLERY_CLOSE(id)}`,
      ]);
      fullBlocks.set(id, { stem, shots: shots.map((shot) => `${kind.dir}/cases/${shot}`) });
    } else {
      galleryBlocks.set(id, lines);
    }
  }
}

// The foot-of-doc section, in leaf order — every whole-screen render, each
// under its own id so the link from the leaf lands somewhere named.
const fullSection = [FULL_OPEN];
for (const id of [...fullBlocks.keys()].sort(byLeafId)) {
  const { stem, shots } = fullBlocks.get(id);
  fullSection.push('', `### \`${id}\` — ${stem.replace(/\.\d+(?:\.\d+)*$/, '')}`, '');
  for (const shot of shots) fullSection.push(`![${stem}](${shot})`);
}
fullSection.push('', FULL_CLOSE);

const rebuilt = [];
let insideGallery = false;
let insideFull = false;
let sawFullSection = false;
for (const line of specLines) {
  if (line.trim() === FULL_OPEN) {
    insideFull = true;
    sawFullSection = true;
    while (rebuilt.at(-1) === '') rebuilt.pop();
    rebuilt.push('', ...fullSection);
    continue;
  }
  if (insideFull) {
    if (line.trim() === FULL_CLOSE) insideFull = false;
    continue;
  }
  if (GALLERY_ANY.test(line)) {
    insideGallery = line.includes('<!-- req-gallery:');
    // The blank line that separated the leaf from its old block is part of the
    // block: leaving it behind would grow one blank per regeneration and the
    // generator would never reach a fixed point.
    if (insideGallery) while (rebuilt.at(-1) === '') rebuilt.pop();
    continue;
  }
  if (insideGallery) continue; // regenerated below
  rebuilt.push(line);
  const m = /^\s*(?:-\s+)?`(\d+(?:\.\d+)+)`/.exec(line);
  if (m && galleryBlocks.has(m[1])) rebuilt.push('', ...galleryBlocks.get(m[1]));
}
if (!sawFullSection && fullBlocks.size) {
  fail(`gallery: requirements.md carries no ${FULL_OPEN} section for its whole-screen renders`);
}
compare(SPEC, `${rebuilt.join('\n').replace(/\n+$/, '')}\n`, 'gallery: requirements.md does not match the generator — run the gate with --write');

// Leaf ids sort by their numbers, never as text: `4.10` follows `4.9`.
function byLeafId(a, b) {
  const l = a.split('.').map(Number);
  const r = b.split('.').map(Number);
  for (let i = 0; i < Math.max(l.length, r.length); i += 1) {
    if ((l[i] ?? 0) !== (r[i] ?? 0)) return (l[i] ?? 0) - (r[i] ?? 0);
  }
  return 0;
}

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

function kindName(kind) {
  return kind.id[0].toUpperCase() + kind.id.slice(1);
}

function renderManifest(kind, cases) {
  const name = kindName(kind);
  const entries = cases.length
    ? `[\n${cases.map((c) => `        ${c.symbol},`).join('\n')}\n    ]`
    : '[]';
  const list = kind.platform
    ? `\n${kind.platform}\n    static let cases: [RequirementCase] = ${entries}\n#else\n    static let cases: [RequirementCase] = []\n#endif`
    : `\n    static let cases: [RequirementCase] = ${entries}`;
  return `// GENERATED by dev/requirements/gate/coverage-gate.mjs --write. Do not edit.
// Swift cannot discover case files at runtime, so this list is what the runner
// executes; the gate fails when it and cases/ disagree.

enum ${name}Manifest {${list}
}
`;
}
