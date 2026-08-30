# Version history

One row per change automatic work makes to this local pack — a prose rule added or removed, a
check created, a rule corrected against a probe or deleted as irrelevant. A run that changed
nothing writes no row; this is the log of what happened to the pack, never a log of runs.

| Date | Task | Change |
|---|---|---|
| 2026-08-30 | `rule-revalidation` | Corrected: **A `mcp__github__*` call risking or hitting the token cap** — none of `actions_list`, `pull_request_read`, `search_issues`, `search_code` carry a `minimal_output` parameter (confirmed against their live schemas); the real reducers are `perPage`/`per_page` and, where offered, a `fields` array. |
| 2026-08-30 | `rule-revalidation` | Corrected: **Naming a new fleet-wide secret, endpoint id, or routine id** — `.claudinite-checks.json` was renamed to `.claudinite-settings.json` (confirmed: the old name is absent from this repo, and `settings-file-names.mjs` documents the rename), and the `CCR_*` convention now lives in `checks/helpers/repo-context.mjs`, not the no-longer-existing `scheduler/resolve-dispatch.mjs`. |
| 2026-08-30 | `rule-revalidation` | Corrected: **Editing `.claudinite-checks.json` or another hand-maintained JSON config from a script** — same rename, retitled to `.claudinite-settings.json`. |
| 2026-08-25 | `growth-extract` | Added: **Running a Flutter/Dart suite command here** — `cd` into the package directory as part of the same command; a bare "No pubspec.yaml" exit is a cwd error, not a test result. |
| 2026-08-25 | `growth-extract` | Added: **Writing or testing Node code for `backend/`** — check CI's pinned `node-version` before relying on version-gated runtime behavior; the sandbox's Node version can be newer. |
| 2026-08-24 | `growth-extract` | Added: **Fetching Cloudflare platform/product docs** — use the `raw.githubusercontent.com/cloudflare/cloudflare-docs` mirror, egress-blocked otherwise. |
| 2026-08-24 | `growth-extract` | Added: **A `mcp__github__*` call hitting the token cap** — `minimal_output`/`per_page` upfront, parse the saved-output file on overflow instead of retrying. |
| 2026-08-24 | `growth-extract` | Added: **Waiting on a GitHub Actions run or PR check** — one wait mechanism, never a background `sleep` timer alongside direct polling. |
| 2026-08-24 | `growth-extract` | Added: **Finding where a Claudinite pack rule is enforced as a check** — read the pack's `declared-checks.json` directly. |
| 2026-08-24 | `growth-extract` | Added: **Reporting a PR's or issue's current status** — query it directly rather than trusting a stale `Context` field. |
| 2026-08-24 | `growth-extract` | Added: **Restoring a file after staging a destructive test edit** — `git checkout HEAD -- <path>`, since a bare `git checkout <path>` restores from the index. |
| 2026-08-24 | `growth-extract` | Added: **Delegating a scan to background `Agent` sub-tasks** — wait for and read each one's output rather than racing ahead with a manual duplicate. |
