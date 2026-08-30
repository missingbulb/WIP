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
  `.claudinite-settings.json` or `.github/workflows/`) — grep the Claudinite engine for the live
  convention first (e.g. `CCR_*` for scheduler token env vars, per
  `.claudinite/shared/engine/checks/helpers/repo-context.mjs`) rather than inventing a
  plausible-sounding name; an invented name gets caught and corrected in review anyway.

- **Editing `.claudinite-settings.json` or another hand-maintained JSON config from a script** —
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

- **Fetching Cloudflare platform/product docs** (`developers.cloudflare.com/...`) for
  product-wiki or architecture research — it's egress-blocked. Fetch the raw source instead from
  the public mirror, `raw.githubusercontent.com/cloudflare/cloudflare-docs`, under
  `production/src/content/docs/<path>.mdx` (shared fragments like instance-type tables live
  under the sibling `.../partials/...` tree).

- **A `mcp__github__*` call risking or hitting "result exceeds maximum allowed tokens"**
  (`actions_list`, `pull_request_read` `get_files`, `search_issues`, `search_code`, …) — pass a
  small `perPage`/`per_page` from the first attempt, and where the tool exposes a `fields` array
  (`search_issues`, `search_code`, `list_issues`, …, but not `pull_request_read`), narrow that
  too — there is no `minimal_output` parameter on any of these. If it still overflows, the error
  names the local file the full result was saved to; parse that with a short script
  (`python3 -c '...json.load(...)'`) for just the fields needed — never retry the same broad
  call, and never `Read` the saved file raw (it can overflow the read cap too).

- **Waiting on a GitHub Actions run or PR check** — resolve the wait through exactly one
  mechanism (the `Monitor` tool's until-loop, or direct polling via `actions_get`/
  `pull_request_read`), never both. A background `sleep` timer left running alongside direct
  polling reports back later as a stale notification that has to be recognized and discarded,
  and pairing a background timer with a *blocking* poll on its output routinely costs 3+
  round-trips once the blocking poll hits the Bash tool's own 120s timeout.

- **Finding where a Claudinite pack rule is enforced as a check** — read that pack's own
  `declared-checks.json` directly rather than grepping `engine/checks/*.mjs` source; a declared
  check is data-driven config, not keyword-searchable script text.

- **Reporting a PR's or issue's current status** — query it directly (`pull_request_read`/
  `issue_read`) before stating it. Text embedded in another item's `Context` field (e.g.
  "(open)") is a snapshot from when that field was written and goes stale.

- **Restoring a file after staging a destructive test edit** (e.g. `git add`-ing an injected
  violation to confirm a check fires on it) — use `git checkout HEAD -- <path>` (or `git reset`
  first). A bare `git checkout <path>` restores from the index, so a staged edit silently
  survives the "restore".

- **Delegating a scan across several files to background `Agent` sub-tasks** — wait for and read
  each one's output before drafting your own analysis of the same file. Racing ahead with a
  manual analysis of the same file in parallel wastes the sub-agent's entire run, and never
  checking back on one at all means it produced nothing usable.

- **Running a Flutter/Dart suite command here** — `cd` into that package's own directory as part
  of the same command, never assuming an earlier edit or suite run (in the same or a prior Bash
  call) left the shell positioned there. A bare `Error: No pubspec.yaml file found` means the cwd
  assumption was wrong, not that the suite ran and failed — a see-it-fail check read off that exit
  code is worthless until the cwd is confirmed and the command redone.

- **Writing or testing Node code for `backend/`** — check what Node version
  `.github/workflows/ci.yml`'s `setup-node` step actually pins for that job before relying on
  version-gated runtime behavior (e.g. `node --test`'s own file-glob expansion needs Node ≥22).
  The agent sandbox's Node version can be newer than what CI runs, so a local pass proves nothing
  about whether the same code passes there.
