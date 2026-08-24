# backend — this repo's Cloudflare Worker segment

Working rules for `backend/`, the Cloudflare side of the product (the Worker API and the
`process-show` Workflow pipeline). Loaded into every session through the rules index, so what
lands here should be a directive an agent can act on. A rule this segment's own structure can
enforce lives in `declared-checks.json` instead — see `bindings-only-in-index` there for the
ports-and-adapters boundary between `src/index.js` and the rest of `src/`.

A lesson that would hold for Cloudflare Workers in general, not just this project, does not belong
here — propose it to the Claudinite canon instead.

- **Tuning a Cloudflare-platform behavior found empirically** (a chunk size, an undocumented
  input ceiling, a rate limit) — put the value in `wrangler.jsonc`'s `vars`, with a comment
  recording what was verified and when, never as a hardcoded constant in `src/`. Workers AI's
  Whisper input ceiling is undocumented, so `TRANSCRIBE_CHUNK_SECONDS` and
  `TRANSCRIBE_CHUNK_OVERLAP_SECONDS` are `vars` for exactly that reason — a value to turn once a
  real show disagrees with it, not a constant to edit and redeploy.

- **Verifying a backend change in an agent session** — install Node >=22 (`wrangler` needs it;
  `backend/package.json`'s `engines` field pins it) and run `npm test` in `backend/`
  (`node --test test/*.test.js`). It needs no Cloudflare account and no network: every rule
  (routing, chunk planning, segmentation, laugh detection) runs as a plain module against the
  fakes in `test/support/fakes.js`, so a change is verified locally rather than only by CI. What
  those fakes cannot prove is named in `backend/README.md`'s "What these tests do not prove".
