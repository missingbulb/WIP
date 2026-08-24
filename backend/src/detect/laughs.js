/**
 * The pipeline's half of the one laugh detector (decision D3).
 *
 * A port of `packages/setlist_core/lib/src/detect.dart`, kept identical so a
 * show detected in the cloud and a set detected on the phone produce numbers
 * that are comparable by construction. The two implementations are held
 * together by `dev/conformance/detector-conformance.GENERATED.json`, which both
 * sides assert against — see that directory's README for how a change to
 * either one is landed.
 */

/** The calibration the product ships. Mirrored from `DetectionSettings.approved`. */
export const APPROVED_SETTINGS = Object.freeze({
  frameMilliseconds: 50,
  minimumDurationMilliseconds: 600,
  thresholdOverBaseline: 2.5,
  baselinePercentile: 0.2,
});

/**
 * Turns a finished recording into the laugh events it contains.
 *
 * @param {Float64Array} samples mono, in -1..1
 * @param {{sampleRate: number, settings?: typeof APPROVED_SETTINGS}} options
 * @returns {Array<{at: number, duration: number, intensity: number}>} seconds from the recording's start
 */
export function detectLaughs(samples, { sampleRate, settings = APPROVED_SETTINGS } = {}) {
  if (!(sampleRate > 0) || samples.length === 0) return [];

  const frameLength = Math.round((sampleRate * settings.frameMilliseconds) / 1000);
  if (frameLength <= 0) return [];

  const levels = frameLevels(samples, frameLength);
  if (levels.length === 0) return [];

  const baseline = percentile(levels, settings.baselinePercentile);
  // A silent room has a zero baseline, and everything is infinitely above
  // nothing. There is no laughter in silence, so there is nothing to report.
  if (baseline <= 0) return [];
  const threshold = baseline * settings.thresholdOverBaseline;

  const frameSeconds = frameLength / sampleRate;
  const minimumFrames = Math.ceil(settings.minimumDurationMilliseconds / 1000 / frameSeconds);

  const events = [];
  let runStart = -1;

  const closeRun = (endExclusive) => {
    if (runStart < 0) return;
    const frames = endExclusive - runStart;
    if (frames >= minimumFrames) {
      let peak = 0;
      for (let i = runStart; i < endExclusive; i++) peak = Math.max(peak, levels[i]);
      events.push({
        at: runStart * frameSeconds,
        duration: frames * frameSeconds,
        // Absolute, not relative to the loudest moment of this recording: an
        // intensity that means "loud for this show" could not be compared with
        // another show, which is the whole point of keeping takes.
        intensity: Math.min(1, Math.max(0, peak)),
      });
    }
    runStart = -1;
  };

  for (let i = 0; i < levels.length; i++) {
    if (levels[i] >= threshold) {
      if (runStart < 0) runStart = i;
    } else {
      closeRun(i);
    }
  }
  // A laugh still going when the recording stops is a laugh that happened.
  closeRun(levels.length);

  return events;
}

/**
 * Root-mean-square amplitude per whole frame. A trailing partial frame is
 * dropped: its level would be measured over a shorter window than every other,
 * and so would not be comparable with them.
 */
function frameLevels(samples, frameLength) {
  const frames = Math.floor(samples.length / frameLength);
  const levels = new Float64Array(frames);
  for (let f = 0; f < frames; f++) {
    let sumSquares = 0;
    const start = f * frameLength;
    for (let i = start; i < start + frameLength; i++) sumSquares += samples[i] * samples[i];
    levels[f] = Math.sqrt(sumSquares / frameLength);
  }
  return levels;
}

/** The value at `fraction` through the sorted levels, by nearest rank. */
function percentile(levels, fraction) {
  const sorted = Float64Array.from(levels).sort();
  const index = Math.min(
    Math.max(Math.round(fraction * (sorted.length - 1)), 0),
    sorted.length - 1,
  );
  return sorted[index];
}
