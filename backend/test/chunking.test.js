import { test } from 'node:test';
import assert from 'node:assert/strict';

import { planChunks, stitchWords } from '../src/chunking/plan.js';

test('a show shorter than one chunk is one chunk', () => {
  assert.deepEqual(planChunks({ durationSeconds: 40, chunkSeconds: 60, overlapSeconds: 2 }), [
    { index: 0, startSeconds: 0, endSeconds: 40 },
  ]);
});

test('chunks overlap by the requested seconds and stop at the show`s end', () => {
  const chunks = planChunks({ durationSeconds: 150, chunkSeconds: 60, overlapSeconds: 2 });
  assert.deepEqual(chunks, [
    { index: 0, startSeconds: 0, endSeconds: 60 },
    { index: 1, startSeconds: 58, endSeconds: 118 },
    { index: 2, startSeconds: 116, endSeconds: 150 },
  ]);
});

test('a show with no duration yet plans nothing', () => {
  assert.deepEqual(planChunks({ durationSeconds: 0, chunkSeconds: 60, overlapSeconds: 2 }), []);
});

test('an overlap as long as the chunk would never advance', () => {
  assert.throws(
    () => planChunks({ durationSeconds: 100, chunkSeconds: 60, overlapSeconds: 60 }),
    RangeError,
  );
});

test('stitching puts every word on the show clock', () => {
  const chunks = planChunks({ durationSeconds: 150, chunkSeconds: 60, overlapSeconds: 2 });
  const words = stitchWords(chunks, [
    [{ word: 'so', start: 0.5, end: 0.8 }],
    [{ word: 'anyway', start: 5, end: 5.4 }],
    [{ word: 'goodnight', start: 30, end: 30.9 }],
  ]);
  assert.deepEqual(words.map((w) => [w.word, w.start]), [
    ['so', 0.5],
    ['anyway', 63],
    ['goodnight', 146],
  ]);
});

test('a word heard by both chunks is kept once, by the chunk that heard more of it', () => {
  const chunks = planChunks({ durationSeconds: 116, chunkSeconds: 60, overlapSeconds: 4 });
  // Both chunks report the same two words out of the overlap (56s–60s): "the"
  // at 57s, near the first chunk's end, and "punchline" at 59s, near the
  // second's start. The seam is 58s.
  const words = stitchWords(chunks, [
    [
      { word: 'the', start: 57, end: 57.2 },
      { word: 'punchline', start: 59, end: 59.6 },
    ],
    [
      { word: 'the', start: 1, end: 1.2 },
      { word: 'punchline', start: 3, end: 3.6 },
    ],
  ]);
  assert.deepEqual(words.map((w) => [w.word, w.start]), [
    ['the', 57],
    ['punchline', 59],
  ]);
});
