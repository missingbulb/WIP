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
