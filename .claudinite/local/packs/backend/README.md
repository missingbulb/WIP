# backend — this repo's Cloudflare Worker segment

Local pack (not portable — see [claudinite-lifecycle](../../../shared/packs/claudinite-lifecycle/RULES.md))
for `backend/`: the Cloudflare Worker API and the `process-show` Workflow pipeline described in
[`../../../../dev/design/architecture.md`](../../../../dev/design/architecture.md) and
[`../../../../backend/README.md`](../../../../backend/README.md). Authored by the
`growth-discover-packs` task once `backend/` became a self-contained sub-project with real,
project-specific working knowledge no canon pack homes (there is no Cloudflare Workers/Wrangler
canon pack) and the repo's general `wip` pack did not already capture.

## Rules (`RULES.md`)

Two prose rules: empirically-found Cloudflare-platform values belong in `wrangler.jsonc`'s `vars`
with a dated comment, never a hardcoded constant; and how to verify a backend change locally
(Node >=22, `npm test` in `backend/`, no account or network needed).

## Checks

| Check | Severity | Enforcement |
|---|---|---|
| `bindings-only-in-index` | blocking | declared check (`declared-checks.json`) + fixture (`bindings-only-in-index.test.mjs`) |

`bindings-only-in-index` guards the ports-and-adapters boundary `backend/README.md` already
documents: every rule under `backend/src/` is a plain module proved against the fakes in
`backend/test/support/`, and only `backend/src/index.js` may touch a Cloudflare binding
(`env.*`) or import `cloudflare:workers`.
