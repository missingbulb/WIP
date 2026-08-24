import { test } from 'node:test';
import assert from 'node:assert/strict';

import { proposeBoundaries, buildSegments } from '../src/pipeline/segment.js';

const words = Array.from({ length: 120 }, (_, i) => ({
  word: `w${i}`,
  start: i * 2,
  end: i * 2 + 1.5,
}));

test('a bit ends where the room reacts, and the next starts at the next word', () => {
  const boundaries = proposeBoundaries({
    words,
    laughEvents: [{ at: 58, duration: 3 }],
  });
  assert.deepEqual(boundaries, [62]);
});

test('the laugh belongs to the bit that earned it', () => {
  const [boundary] = proposeBoundaries({ words, laughEvents: [{ at: 40, duration: 4 }] });
  assert.ok(boundary >= 44, 'the boundary falls at or after the laugh`s end, never inside it');
});

test('two laughs inside one bit do not cut it in three', () => {
  const boundaries = proposeBoundaries({
    words,
    laughEvents: [
      { at: 30, duration: 2 },
      { at: 38, duration: 2 },
      { at: 120, duration: 3 },
    ],
  });
  assert.deepEqual(boundaries, [32, 124]);
});

test('a laugh with nothing after it ends the show rather than opening a segment', () => {
  assert.deepEqual(proposeBoundaries({ words, laughEvents: [{ at: 238, duration: 4 }] }), []);
});

test('similarity minima propose boundaries alongside the laughs', () => {
  const boundaries = proposeBoundaries({
    words,
    laughEvents: [{ at: 30, duration: 2 }],
    similarityMinima: [100],
  });
  assert.deepEqual(boundaries, [32, 100]);
});

test('segments carry the words that fall inside them', () => {
  const segments = buildSegments({ boundaries: [10], words, durationSeconds: 20 });
  assert.deepEqual(
    segments.map((s) => [s.startSeconds, s.endSeconds, s.text]),
    [
      [0, 10, 'w0 w1 w2 w3 w4'],
      [10, 20, 'w5 w6 w7 w8 w9'],
    ],
  );
});

test('a show with no boundaries is one segment', () => {
  const segments = buildSegments({ boundaries: [], words: words.slice(0, 3), durationSeconds: 6 });
  assert.equal(segments.length, 1);
  assert.equal(segments[0].text, 'w0 w1 w2');
});
