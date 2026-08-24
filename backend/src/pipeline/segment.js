/**
 * Where one bit ends and the next begins, proposed from what the show itself
 * did: the room reacted, and then the comedian started something else.
 *
 * Pure. The two judgments this cannot make — whether two stretches of
 * transcript are about the same thing, and what a bit should be called — are
 * the pipeline's model calls, and they arrive here as `similarityMinima` and
 * are applied to the output afterwards.
 */

/**
 * Boundary times, in seconds from the show's start.
 *
 * A boundary sits at the first word after a laugh has finished: the reaction
 * belongs to the bit that earned it, not to the one that follows. A laugh with
 * no word after it ends the show rather than opening a segment.
 *
 * @param {{
 *   words: Array<{word: string, start: number, end: number}>,
 *   laughEvents: Array<{at: number, duration: number}>,
 *   similarityMinima?: number[],
 *   minimumSegmentSeconds?: number,
 * }} input
 */
export function proposeBoundaries({
  words,
  laughEvents,
  similarityMinima = [],
  minimumSegmentSeconds = 20,
}) {
  const candidates = [];
  for (const laugh of laughEvents) {
    const resumesAt = laugh.at + laugh.duration;
    const next = words.find((word) => word.start >= resumesAt);
    if (next) candidates.push(next.start);
  }
  for (const minimum of similarityMinima) candidates.push(minimum);

  candidates.sort((a, b) => a - b);

  // Two laughs inside one bit are one bit, not three. The minimum is what keeps
  // a run of big laughs from shredding a five-minute story into fragments; it
  // is deliberately a floor on length rather than a judgment about content,
  // which is what the model pass above it is for.
  const boundaries = [];
  for (const candidate of candidates) {
    const previous = boundaries.length ? boundaries[boundaries.length - 1] : 0;
    if (candidate - previous >= minimumSegmentSeconds) boundaries.push(candidate);
  }
  return boundaries;
}

/**
 * The spans those boundaries cut the show into, each carrying its own words.
 *
 * @returns {Array<{startSeconds: number, endSeconds: number, text: string}>}
 */
export function buildSegments({ boundaries, words, durationSeconds }) {
  const edges = [0, ...boundaries, durationSeconds];
  const segments = [];
  for (let i = 0; i < edges.length - 1; i++) {
    const [start, end] = [edges[i], edges[i + 1]];
    if (end <= start) continue;
    segments.push({
      startSeconds: start,
      endSeconds: end,
      text: words
        .filter((word) => word.start >= start && word.start < end)
        .map((word) => word.word)
        .join(' '),
    });
  }
  return segments;
}
