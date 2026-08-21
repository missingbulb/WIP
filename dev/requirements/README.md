# Running the executable requirements

[`requirements.md`](requirements.md) is the spec; everything here executes it.
The framework's conventions — layout, ids, kinds, the bijection — are the
`executable-requirements` pack's, so this file carries only what is specific to
this project.

```
node dev/requirements/gate/coverage-gate.mjs          # the bijection gate
node dev/requirements/gate/coverage-gate.mjs --write  # regenerate the manifests and the gallery
swift test                                            # run the cases
```

The gate runs anywhere Node does. The cases need a Swift toolchain, which agent
sessions on this repo do not have — they run in CI (`requirements` job for the
cases, `app` for the iPad app build), so a change to anything under `Sources/`
or here is verified by the pull request's checks, not locally.

Two things are generated and must never be hand-edited: each kind's
`Manifest.GENERATED.swift` (Swift discovers no case file at runtime, so the
manifest is what [`Runner.swift`](Runner.swift) executes) and the golden gallery
embedded in `requirements.md`. Regenerate both with `--write`.

Screen goldens are never written by hand or by a local run: the
`refresh-goldens` workflow re-renders every one on a simulator and commits the
result, so an intended UI change lands as PNGs in the diff for the owner to
approve. Run it from the Actions tab, or put `[refresh goldens]` in the commit
message of a push on the branch. It works by dropping
`screen/.refresh` beside the cases for the length of one run. It is never how a red case gets fixed — a
render that changed unintentionally is a bug in the change.

`gate/pending.json` is the burn-down list of leaves that are specified but not
yet executable, each with the reason it cannot be. A leaf enters it only
deliberately, carries the loud `⚠ TBD` marker in the spec, and leaves it when a
case claims it.
