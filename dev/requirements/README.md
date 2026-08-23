# Running the executable requirements

[`requirements.md`](requirements.md) is the spec; everything here executes it.
The framework's conventions — layout, ids, kinds, the bijection — are the
`executable-requirements` pack's, so this file carries only what is specific to
this project.

```
node dev/requirements/gate/coverage-gate.mjs          # the bijection gate
node dev/requirements/gate/coverage-gate.mjs --write  # regenerate the manifests and the gallery
flutter test runner_test.dart                         # every kind, from dev/requirements
```

## The kinds

| kind | proves | expected |
|---|---|---|
| `screen` | a rendered resting state | one golden PNG beside the case, pixel-exact, cropped to the region the leaf is about |
| `saga` | a multi-step story | one captioned frame per step, `<slug>.<id>.step-NN.png`, plus the generated `.captions.json` |
| `behavior` | a driven gesture and what it produces | coded assertions against the fakes' recordings |
| `logic` | a pure product rule | a coded `verify()` against shipped code |

A case file is `<kind>/cases/<slug>.<id>.case.dart` — the slug names the
feature, so retitling a section never forces a rename. The folder is the kind:
a new way of asserting a requirement is a directory plus a registry entry in
[`gate/kinds.mjs`](gate/kinds.mjs). Cases reach the runner through the
per-kind `*_manifest.GENERATED.dart` files, which the gate writes from disk —
never edit one by hand.

## The lanes

Everything runs anywhere Flutter does, Linux included: the test renderer draws
and compares goldens headless, with no display server and no simulator. So a
change here is verified locally, in an agent session, before it reaches a pull
request — see the repo's own rules for the SDK install. CI runs the same
commands on `ubuntu-latest`.

## What a screen case captures

A screen case names the [`StageRegion`](../../packages/setlist_ui/lib/src/stage_region.dart)
its leaf is about, and the golden is that region cropped out of a full render of
the composed screen. The screen publishes its own region bounds through widget
keys, so a case asks for `.clocks` or `.jokeBody` and never for coordinates;
adding a region is a case in that enum plus a key on the widget it names.

Omitting the region captures the whole screen. That is a deliberate exception —
for a leaf that claims something about the screen as a whole, like one that
compares an element against everything around it — and the case says why in a
`// whole-screen: <reason>` comment, which the gate requires. A case that
silently captured everything would still pass; it would just prove less, and
that is the failure this kind exists to avoid. Those whole-screen renders are
also what the gallery embeds at the foot of the spec, one per size class.

## Goldens

An intended UI change lands as PNGs in the diff for the owner to approve:
re-render with `flutter test runner_test.dart --update-goldens`, then run the
gate with `--write` so the gallery moves with them. That is never how a red case
gets fixed — a render that changed unintentionally is a bug in the change, and
the procedure for a mismatch (surface actual, expected and diff, ask, only then
re-baseline) is canon in the `writing-tests` skill.

When a case fails, its actual and diff renders are written to a gitignored
`failures/` directory beside the case, and CI uploads them as the
`requirement-failures` artifact.

## Determinism

Goldens are byte-compared, so every input that could move a pixel is pinned: the
SDK version in [`.flutter-version`](../../.flutter-version), the product's fonts
loaded from the asset bundle by `loadProductFonts`, one reference clock, and a
fixed size per size class. Fonts are the one with teeth — without them the
renderer draws every glyph as an identical box, and a golden happily proves
nothing about the text it contains.
