import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

import { detectLaughs, APPROVED_SETTINGS } from '../src/detect/laughs.js';

const vectors = JSON.parse(
  readFileSync(new URL('../../dev/conformance/detector-conformance.GENERATED.json', import.meta.url)),
);

// Two languages' floating point, so not bit-identity: what conformance claims is
// that the same recording yields the same events, not that IEEE rounds the same
// way through two compilers. A drift the product would ever notice moves a
// boundary by a whole frame, which is twelve orders of magnitude bigger.
const TOLERANCE = 1e-9;

test('the port ships the calibration the Dart detector ships', () => {
  assert.deepEqual({ ...APPROVED_SETTINGS }, vectors.settings);
});

for (const vector of vectors.cases) {
  test(`${vector.name} — ${vector.what}`, () => {
    const bytes = Buffer.from(vector.samples, 'base64');
    const samples = new Float64Array(
      bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength),
    );

    const events = detectLaughs(samples, { sampleRate: vector.sampleRate });

    assert.equal(events.length, vector.events.length, 'event count');
    events.forEach((event, i) => {
      const expected = vector.events[i];
      for (const field of ['at', 'duration', 'intensity']) {
        assert.ok(
          Math.abs(event[field] - expected[field]) < TOLERANCE,
          `${field}: ${event[field]} vs ${expected[field]}`,
        );
      }
    });
  });
}
