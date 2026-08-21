// The kind registry: one entry per way a requirement can be asserted. The
// folder a case lives in IS its kind, so adding a kind is this entry plus the
// directory — no gate rule mentions a kind by name.
export const KINDS = [
  {
    id: 'screen',
    dir: 'screen',
    // A rendered resting state, pixel-exact against a committed golden the
    // owner approves by sight.
    images: true,
    // Rendering needs SwiftUI and a simulator, so this kind runs only in the
    // `app` CI job; elsewhere its manifest is empty.
    platform: '#if canImport(SwiftUI) && os(iOS)',
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
    platform: '#if canImport(SwiftUI) && os(iOS)',
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

export const CASE_EXT = 'swift';
export const GOLDEN_EXT = 'png';
