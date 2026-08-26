// backend — this repo's Cloudflare Worker segment: everything specific to
// working in backend/, and portable nowhere else. Its rules, and the checks
// that carry them, live here.
//
// The id is this directory's name and the prose is the RULES.md beside this
// file — both by convention (engine/pack_loader/pack-conventions.mjs), so
// neither is declared here.
export default {
  version: 1,
  ruleRoutingGuidance: {
    belongs: 'working rules for backend/ — the Cloudflare Worker: bindings, the Workflow, D1, R2, wrangler config',
    excludes: "the Flutter app or any other segment — that's wip; portable Workers knowledge — propose it to the canon",
  },
  detect: null,
  marker: null,
  worldRules: [],
};
