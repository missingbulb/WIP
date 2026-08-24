/**
 * Turning a show's duration into the chunks transcription runs over, and the
 * chunks' word timings back into one show-long transcript.
 *
 * Pure: no audio, no clock, no bindings. What makes chunking necessary at all —
 * Workers AI's undocumented input ceiling (risk R3) — is a number the caller
 * passes in, because the only way to know it is to find it empirically against
 * the real service.
 */

/**
 * @param {{durationSeconds: number, chunkSeconds: number, overlapSeconds: number}} plan
 * @returns {Array<{index: number, startSeconds: number, endSeconds: number}>}
 *   spans to cut, each overlapping the one before it
 */
export function planChunks({ durationSeconds, chunkSeconds, overlapSeconds }) {
  if (!(durationSeconds > 0)) return [];
  if (!(chunkSeconds > 0)) throw new RangeError('chunkSeconds must be positive');
  if (!(overlapSeconds >= 0) || overlapSeconds >= chunkSeconds) {
    throw new RangeError('overlapSeconds must be zero or more, and shorter than a chunk');
  }

  const chunks = [];
  const stride = chunkSeconds - overlapSeconds;
  for (let start = 0; start < durationSeconds; start += stride) {
    chunks.push({
      index: chunks.length,
      startSeconds: start,
      endSeconds: Math.min(start + chunkSeconds, durationSeconds),
    });
    if (start + chunkSeconds >= durationSeconds) break;
  }
  return chunks;
}

/**
 * Stitches per-chunk word timings into one transcript on the show's own clock.
 *
 * Each chunk is transcribed with its neighbour's tail included, so the model
 * has context across the cut — which means every word in an overlap arrives
 * twice. The seam is the middle of the overlap: words before it belong to the
 * earlier chunk, words after it to the later one. Splitting there rather than
 * at either edge keeps every word attributed to the chunk that heard the most
 * of it.
 *
 * @param {Array<{index: number, startSeconds: number, endSeconds: number}>} chunks
 * @param {Array<Array<{word: string, start: number, end: number}>>} perChunkWords
 *   timings relative to each chunk's own start
 */
export function stitchWords(chunks, perChunkWords) {
  if (chunks.length !== perChunkWords.length) {
    throw new RangeError('one word list per planned chunk');
  }

  const words = [];
  chunks.forEach((chunk, i) => {
    const previous = chunks[i - 1];
    const seamBefore = previous
      ? (chunk.startSeconds + previous.endSeconds) / 2
      : -Infinity;
    const next = chunks[i + 1];
    const seamAfter = next ? (next.startSeconds + chunk.endSeconds) / 2 : Infinity;

    for (const word of perChunkWords[i]) {
      const start = chunk.startSeconds + word.start;
      if (start < seamBefore || start >= seamAfter) continue;
      words.push({ word: word.word, start, end: chunk.startSeconds + word.end });
    }
  });
  return words;
}
