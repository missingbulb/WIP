# wip — this repo's own rules

The capture surface for lessons **specific to this repository**. Loaded into every session
through the rules index, so what lands here should be a directive an agent can act on, not a
description of how something works.

A lesson that would hold in another repo does not belong here — propose it to the Claudinite
canon instead, where every repo gets it.

- **Doing Swift/iPad-app work in an agent session here** — there is no Swift toolchain and no
  macOS: the toolchain download is blocked by the environment's network policy, not merely
  missing. Nothing Swift can be compiled or run locally, so every Swift/iPad-app change is
  verified only by CI (the macOS runner) — never by a local build.

- **Naming a new fleet-wide secret, endpoint id, or routine id** (queue/scheduler wiring in
  `.claudinite-checks.json` or `.github/workflows/`) — grep the Claudinite engine for the live
  convention first (e.g. `CCR_*` for scheduler token env vars, per
  `.claudinite/shared/engine/scheduler/resolve-dispatch.mjs`) rather than inventing a
  plausible-sounding name; an invented name gets caught and corrected in review anyway.

- **Editing `.claudinite-checks.json` or another hand-maintained JSON config from a script** —
  a `json.load`/`json.dumps` round-trip re-serializes the *whole* file (reordering/rewrapping
  keys it never meant to touch), turning a one-field addition into an oversized diff that has
  to be reverted and redone. Make a narrow, targeted text edit instead.

- **Pushing a change that touches a checked file** (e.g. `product-wiki/` content) —
  `check_the_world.mjs` is wired into CI, not the Stop hook, so nothing runs it locally on its
  own. Run
  `node .claudinite/shared/engine/checks/check_the_world.mjs` before pushing rather than waiting
  for CI to report red.

- **Fetching an Apple Developer Documentation page** (`developer.apple.com/documentation/...`) for
  product-wiki research — it's JS-rendered, so `WebFetch` returns only the page title. Fetch the
  JSON mirror at `developer.apple.com/tutorials/data/documentation/...` instead.
