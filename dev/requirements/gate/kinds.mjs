// The kind registry: one entry per way a requirement can be asserted. The
// folder a case lives in IS its kind, so adding a kind is this entry plus the
// directory — no gate rule mentions a kind by name.
//
// No kind carries a platform guard any more: every kind renders in the Flutter
// test harness on Linux, which is what lets CI run without a macOS runner
// (decision D9).
export const KINDS = [
  {
    id: 'screen',
    dir: 'screen',
    // A rendered resting state, pixel-exact against a committed golden the
    // owner approves by sight, cropped to the element its leaf is about.
    images: true,
    scoped: true,
  },
  {
    id: 'saga',
    dir: 'saga',
    // A multi-step story: one captioned frame per step, so the gallery shows
    // what arriving, tapping or time passing changes. Frames are numbered
    // `<slug>.<id>.step-NN.png`; the captions ride beside them as generated
    // JSON, because a caption list hand-maintained in Markdown drifts from the
    // frames it labels.
    images: true,
    frames: true,
  },
  {
    id: 'behavior',
    dir: 'behavior',
    // A driven gesture and the consequence it produces against the fakes'
    // recordings. A screenshot cannot see a gesture, so images are refused.
    images: false,
  },
  {
    id: 'logic',
    dir: 'logic',
    // A pure product rule, verified against the shipped code.
    images: false,
  },
];

export const CASE_EXT = 'dart';
export const GOLDEN_EXT = 'png';
