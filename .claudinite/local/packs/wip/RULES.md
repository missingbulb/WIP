# wip — this repo's own rules

The capture surface for lessons **specific to this repository**. Loaded into every session
through the rules index, so what lands here should be a directive an agent can act on, not a
description of how something works.

A lesson that would hold in another repo does not belong here — propose it to the Claudinite
canon instead, where every repo gets it.

- **Verifying an app change in an agent session here** — install the Flutter SDK pinned in
  `.flutter-version` and run the suites: `dart test` in `packages/setlist_core`, `flutter test`
  in `packages/setlist_ui`, and `flutter test runner_test.dart` in `dev/requirements` (its cases
  sit outside a `test/` folder, so the bare `flutter test` command finds nothing there). Goldens
  render and compare headless on Linux with no display server, so a change is verified locally
  rather than only by CI. What still cannot be verified anywhere but a device is the native
  recorder under `app/ios` and `app/android` — neither toolchain exists here.

- **Doing real file or image I/O inside `testWidgets`** — wrap it in `tester.runAsync`. In the
  fake-async test zone the future never completes, and the case hangs rather than failing.

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

- **Reading a captured `conversation-logs` file** (`git show origin/conversation-logs:<file>`, or
  the `Read` tool on a checked-out copy) — a small line-count `offset`/`limit` is not a safe
  bound. A single JSONL line can be one large `tool_use`/`tool_result` running tens of thousands
  of characters, so even a short window can overflow the 25,000-token read cap. Check line
  lengths first (`awk '{print length}' <file> | sort -n | tail`) or condense the file with a
  script before attempting a raw `Read`.
