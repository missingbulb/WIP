import { test } from 'node:test';
import assert from 'node:assert/strict';

import { processShow } from '../src/pipeline/process-show.js';

/** A show of `durationSeconds`, whose audio is loud between `laughAt` spans. */
function fakePorts({ durationSeconds = 300, words = null, laughSpans = [[100, 3]] } = {}) {
  const sampleRate = 500;
  const samples = new Float64Array(durationSeconds * sampleRate);
  for (let i = 0; i < samples.length; i++) {
    const t = i / sampleRate;
    const loud = laughSpans.some(([at, length]) => t >= at && t < at + length);
    samples[i] = (loud ? 0.2 : 0.01) * (i % 2 ? -1 : 1);
  }

  const transcript =
    words ??
    Array.from({ length: durationSeconds / 2 }, (_, i) => ({
      word: `w${i}`,
      start: i * 2,
      end: i * 2 + 1,
    }));

  const calls = { cuts: [], transcribed: 0, artifacts: new Map(), saved: null, steps: [] };
  return {
    calls,
    ports: {
      audio: {
        probe: async () => ({ durationSeconds, sampleRate }),
        cut: async (key, span) => {
          calls.cuts.push(span);
          return new ArrayBuffer(8);
        },
        samples: async () => ({ samples, sampleRate }),
      },
      ai: {
        transcribe: async () => {
          // Each chunk hears the words that fall inside it, on its own clock.
          const span = calls.cuts[calls.transcribed++];
          return {
            words: transcript
              .filter((w) => w.start >= span.startSeconds && w.start < span.endSeconds)
              .map((w) => ({ ...w, start: w.start - span.startSeconds, end: w.end - span.startSeconds })),
          };
        },
        similarityMinima: async () => [],
        nameSegments: async (segments) => segments.map((_, i) => `Bit ${i + 1}`),
      },
      store: {
        putArtifact: async (key, body) => calls.artifacts.set(key, body),
        saveResults: async (showId, results) => {
          calls.saved = { showId, ...results };
        },
      },
      config: { chunkSeconds: 60, overlapSeconds: 2 },
      step: async (name, work) => {
        calls.steps.push(name);
        return work();
      },
    },
  };
}

const SHOW = { showId: 'show-1', audioKey: 'shows/device-a/show-1' };

test('the pipeline runs its steps in the order the design names', async () => {
  const { ports, calls } = fakePorts();
  await processShow(SHOW, ports);
  assert.deepEqual(calls.steps, ['probe', 'transcribe', 'laugh-detect', 'segment', 'persist']);
});

test('the whole show is transcribed, chunk by chunk, onto one clock', async () => {
  const { ports, calls } = fakePorts({ durationSeconds: 300 });
  await processShow(SHOW, ports);

  assert.equal(calls.cuts.length, 6, 'a five-minute show at 60s chunks with 2s overlap');
  const { words } = calls.artifacts.get('artifacts/show-1/transcript.json');
  assert.equal(words[0].start, 0);
  assert.ok(words.at(-1).start > 290, 'the last word is at the end of the show, not of a chunk');
});

test('artifacts go to R2, never into a step result', async () => {
  const { ports, calls } = fakePorts();
  await processShow(SHOW, ports);
  assert.deepEqual(
    [...calls.artifacts.keys()],
    ['artifacts/show-1/transcript.json', 'artifacts/show-1/laughs.json'],
  );
});

test('the room`s reactions become laugh events and cut the show into bits', async () => {
  const { ports, calls } = fakePorts({ laughSpans: [[100, 3], [200, 4]] });
  const summary = await processShow(SHOW, ports);

  assert.equal(summary.laughEvents, 2);
  assert.equal(summary.segments, 3, 'two boundaries make three bits');
  assert.deepEqual(
    calls.saved.segments.map((s) => s.title),
    ['Bit 1', 'Bit 2', 'Bit 3'],
  );
});

test('every boundary the pipeline proposed says so', async () => {
  const { ports, calls } = fakePorts();
  await processShow(SHOW, ports);
  assert.ok(calls.saved.segments.every((segment) => segment.provenance === 'detected'));
});

test('a show the room never reacted to is one bit, not none', async () => {
  const { ports, calls } = fakePorts({ laughSpans: [] });
  const summary = await processShow(SHOW, ports);
  assert.equal(summary.laughEvents, 0);
  assert.equal(summary.segments, 1);
  assert.equal(calls.saved.durationSeconds, 300);
});
