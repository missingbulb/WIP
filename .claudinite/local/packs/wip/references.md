# References — rationale behind this pack's rules

Maintenance and review material for the `writing-pack-prose` references convention: each entry
carries the reason a rule exists, written so a periodic review can reaffirm — or retire — it. An
end-of-line `(n)` marker in `RULES.md` cites `RULES-n`. No session loads this file for daily
work.

- **(RULES-1)** Porting the executable spec to the Flutter harness let every kind render headless
  on Linux, which is what let CI drop both macOS jobs (decision D9, #40) — there is no macOS
  runner in this repo. Reaffirm by confirming Linux still renders every kind headless; retire the
  claim only if a kind again needs a real display, or CI regains a macOS lane.
- **(RULES-2)** Wiring the queue's agent invocation endpoint (#28) needed a fleet-wide secret
  name; the live convention (`CCR_*`, e.g. `CCR_ROUTINE_TOKEN`) was found by grepping
  `.claudinite/shared/engine/scheduler/resolve-dispatch.mjs` rather than guessed. Reaffirm by
  checking that file still defines the convention before retiring the pointer.
- **(RULES-3)** A sandbox Node newer than CI's pinned `setup-node` version masked a version-gated
  bug — `node --test`'s file-glob discovery needs Node ≥22 — until it broke in CI (#87); PR #89
  already made the CI pin config-enforced. Reaffirm by checking whether the sandbox's Node
  version has since been pinned to match CI's.
