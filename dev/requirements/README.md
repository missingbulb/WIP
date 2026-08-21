# Running the executable requirements

[`requirements.md`](requirements.md) is the spec; everything here executes it.
The framework's conventions — layout, ids, kinds, the bijection — are the
`executable-requirements` pack's, so this file carries only what is specific to
this project.

```
node dev/requirements/gate/coverage-gate.mjs          # the bijection gate
node dev/requirements/gate/coverage-gate.mjs --write  # regenerate the manifests and the gallery
swift test                                            # the kinds that need no simulator
```

## The kinds

| kind | proves | expected | runs |
|---|---|---|---|
| `screen` | a rendered resting state | one golden PNG beside the case, pixel-exact | simulator |
| `saga` | a multi-step story | one captioned frame per step, `<slug>.<id>.step-NN.png`, plus the generated `.captions.json` | simulator |
| `behavior` | a driven gesture and what it produces | coded assertions against the fakes' recordings | anywhere |
| `logic` | a pure product rule | a coded `verify()` against shipped code | anywhere |

A case file is `<kind>/cases/<slug>.<id>.case.swift` — the slug names the
feature, so retitling a section never forces a rename. The folder is the kind:
a new way of asserting a requirement is a directory plus a registry entry in
[`gate/kinds.mjs`](gate/kinds.mjs) and a line in [`Runner.swift`](Runner.swift).

## The lanes

The gate runs anywhere Node does. The cases need a Swift toolchain, which agent
sessions on this repo do not have — they run in CI (`requirements` for the
kinds above that need no simulator, `app` for the app build plus `screen` and
`saga`), so a change to anything under `Sources/` or here is verified by the
pull request's checks, never locally.

## Goldens

Screen and saga goldens are never written by hand or by a local run: the
`refresh-goldens` workflow re-renders every one on a simulator and commits the
result, so an intended UI change lands as PNGs in the diff for the owner to
approve. Run it from the Actions tab, or put `[refresh goldens]` in the commit
message of a push on the branch. It works by dropping `screen/.refresh` beside
the cases for the length of one run. It is never how a red case gets fixed — a
render that changed unintentionally is a bug in the change.

The goldens are pixel-exact, and what renders them is the simulator's iOS
runtime — so a runner image that ships a new runtime can move every one of them
at once. That shows up as the whole screen kind going red together, which is the
tell: a real regression moves one or two. The fix is a refresh run and a look at
the diff, not a tolerance.

## Generated, never hand-edited

Each kind's `<Kind>Manifest.GENERATED.swift` (Swift discovers no case file at
runtime, so the manifest is what `Runner.swift` executes), each saga's
`.captions.json`, and the gallery blocks embedded in `requirements.md` between
`<!-- req-gallery:<id> -->` markers. Regenerate the first and last with
`--write`; captions come from the refresh run, beside the frames they label.

## The burn-down list

[`gate/pending.json`](gate/pending.json) holds the leaves that are specified but
not yet executable, each with the reason it cannot be. A leaf enters it only
deliberately, carries the loud `⚠ TBD` marker in the spec, and leaves it when a
case claims it.
