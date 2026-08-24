/**
 * What happens to a show between the upload landing and the comedian seeing it
 * cut into bits: probe, transcribe, laugh-detect, segment, persist.
 *
 * Written against ports rather than bindings — `audio`, `ai`, `store` — for two
 * reasons. Workers AI's real behaviour on a chunk of club audio is the thing
 * Phase B exists to find out, so the orchestration has to be provable
 * separately from it; and a Workflow step's result is capped at 1 MiB, so every
 * artifact of any size goes to R2 and steps pass keys, which is a discipline
 * worth stating in one place.
 */

import { detectLaughs } from '../detect/laughs.js';
import { planChunks, stitchWords } from '../chunking/plan.js';
import { proposeBoundaries, buildSegments } from './segment.js';

/**
 * @param {{showId: string, audioKey: string}} show
 * @param {{
 *   audio: {probe: (key) => Promise<{durationSeconds: number, sampleRate: number}>,
 *           cut: (key, span) => Promise<ArrayBuffer>,
 *           samples: (key) => Promise<{samples: Float64Array, sampleRate: number}>},
 *   ai: {transcribe: (audio) => Promise<{words: Array<{word: string, start: number, end: number}>}>,
 *        similarityMinima: (segments) => Promise<number[]>,
 *        nameSegments: (segments) => Promise<string[]>},
 *   store: {putArtifact, saveResults},
 *   config: {chunkSeconds: number, overlapSeconds: number},
 *   step: (name, work) => Promise<any>,
 * }} ports
 */
export async function processShow(show, ports) {
  const { step } = ports;

  const probe = await step('probe', () => ports.audio.probe(show.audioKey));

  const transcript = await step('transcribe', async () => {
    const chunks = planChunks({
      durationSeconds: probe.durationSeconds,
      chunkSeconds: ports.config.chunkSeconds,
      overlapSeconds: ports.config.overlapSeconds,
    });
    const perChunkWords = [];
    for (const chunk of chunks) {
      // Serially, not in parallel: the ASR rate limit swallows a show either
      // way, and a chunk at a time keeps one 60-minute show from taking the
      // whole account's budget while another comedian waits.
      const audio = await ports.audio.cut(show.audioKey, chunk);
      const { words } = await ports.ai.transcribe(audio);
      perChunkWords.push(words);
    }
    const words = stitchWords(chunks, perChunkWords);
    await ports.store.putArtifact(`artifacts/${show.showId}/transcript.json`, { words });
    return { words };
  });

  const laughs = await step('laugh-detect', async () => {
    const { samples, sampleRate } = await ports.audio.samples(show.audioKey);
    const events = detectLaughs(samples, { sampleRate });
    await ports.store.putArtifact(`artifacts/${show.showId}/laughs.json`, { events });
    return events;
  });

  const segments = await step('segment', async () => {
    const rough = buildSegments({
      boundaries: proposeBoundaries({ words: transcript.words, laughEvents: laughs }),
      words: transcript.words,
      durationSeconds: probe.durationSeconds,
    });
    // The model's two judgments, in the order that lets the second see the
    // first: where the subject actually changes, then what to call each bit.
    const minima = await ports.ai.similarityMinima(rough);
    const settled = buildSegments({
      boundaries: proposeBoundaries({
        words: transcript.words,
        laughEvents: laughs,
        similarityMinima: minima,
      }),
      words: transcript.words,
      durationSeconds: probe.durationSeconds,
    });
    const titles = await ports.ai.nameSegments(settled);
    return settled.map((segment, i) => ({
      ...segment,
      title: titles[i] ?? null,
      // Every boundary here came from the pipeline. A comedian's own tap
      // overrides it later, and the two are told apart by this.
      provenance: 'detected',
    }));
  });

  await step('persist', () =>
    ports.store.saveResults(show.showId, {
      durationSeconds: probe.durationSeconds,
      segments,
      laughEvents: laughs,
    }),
  );

  return { segments: segments.length, laughEvents: laughs.length };
}
