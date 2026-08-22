# Set list — architecture & system design

The comedians' set-list app (working title "Set list"; repo working name
Claudinite) and its Cloudflare backend. Product behavior is specified by
[`setlist-requirements.md`](setlist-requirements.md) (the owner's screen-level
requirements) and illustrated by
[`mockups/setlist-ipad-mockups.html`](mockups/setlist-ipad-mockups.html); this
document is the system shape those requirements run on. The numbered executable
spec lives in [`../requirements/requirements.md`](../requirements/requirements.md)
— this doc does not duplicate requirement text.

Owner constraints this design serves:

1. **Ship to the app stores ASAP** — simplified, client-only flows are
   acceptable first.
2. **A backend process outside the app**: ingest a full-show recording, run
   segmentation + laugh detection offline/batch, and hand the comedian a link to
   their segmented show as a QR code.
3. **Cloudflare is the cloud platform.**
4. **iOS and Android, across phone and tablet sizes.**
5. **No macOS CI runner** until build artifacts are published to a store.

## System context

```
┌────────────────────────┐         ┌──────────────────────────────────┐
│ Flutter app (iOS,      │         │ Cloudflare                        │
│  Android; phone+tablet)│ upload  │  Worker API ── Workflow pipeline  │
│  stage mode · record   │────────▶│  R2 audio/artifacts   D1 metadata │
│  laugh detect · review │◀────────│  Workers AI (Whisper, embeddings, │
│  QR display            │ results │   LLM)   Container (ffmpeg)       │
└────────────────────────┘         │  share page (static assets + R2)  │
                                   └──────────────────────────────────┘
          ┌──────────────┐  HTTPS                  │
          │ Comedian's    │◀───────────────────────┘
          │ browser (QR)  │   share link: player + segmented set
          └──────────────┘
```

Two actors: the **app user** (records their own sets live, or records a whole
show) and the **share recipient** (a comedian with no app, opening a QR link to
their already-segmented set in a browser). The share page is also the product's
acquisition surface — every shared set demos the product to a comedian.

## Phasing

Ordered by the owner's ship-ASAP constraint. Each phase is releasable on its
own; the build plan's tracking issue carries the step-level checkboxes.

### Phase A — client-only MVP (store submission target)

No backend, no accounts, everything on device. This is deliberately the
BitBinder-style "100% local, works offline" posture — a trust feature for
material-protective comedians, not just a shortcut.

- **Set list management**: jokes as cards, set builder, the stage-mode screen
  from the mockups (current joke, pacing bar, countdown, 3×3 grid).
- **Recording**: continuous capture through the set, AAC on disk, background
  audio so a locked screen keeps recording.
- **Laugh detection, after the set**: a loudness-envelope pass over the finished
  recording (D7), producing timestamped events beside the audio. No classifier
  and no model, on device or in the cloud.
- **Segmentation, manual**: card taps mark bit boundaries (the mockups' "Manual
  switch" mode). Autodetect is explicitly out of Phase A.
- **Review**: per-show timeline of laugh events aligned to bit boundaries; the
  joke-analysis screen fed by manual boundaries + laugh events only (no
  transcript yet — transcript-dependent affordances stay hidden).
- **No transcription in Phase A.** On-device long-form ASR costs ship-speed on
  both platforms; transcripts arrive with the backend in Phase B.

### Phase B — Cloudflare batch pipeline + QR share

The owner-described backend flow: record a full show (multiple comedians or a
full set), upload, process offline, hand out QR links.

- Upload from the app to R2 (presigned, direct).
- Pipeline (Workflow): transcribe → laugh-detect → segment → persist → publish
  share link.
- Share page in the browser: audio player streaming from R2, segmented set with
  laugh timeline, per-bit jump links. QR code rendered **on device** from the
  share URL — no server QR endpoint.

### Phase C — the analysis product

Cross-show joke analysis (the mockups' screen 2 at full power): takes of one
joke side by side, anomaly flags, room metadata queries. Autodetect-bits live
mode, informed by Phase B's segmentation quality. Sync of the on-device library
through the same backend. Designed later, on Phase B's data.

## Client design

One Flutter codebase for iOS and Android, phone and tablet (D1). Modules named
by responsibility:

- **Library** — jokes, sets, shows; local store; everything user-deletable lives
  in the app's own container.
- **Stage** — the live screen: set list state machine (queued → live → told),
  countdown, pacing bar. Reads Capture's amplitude feed for the waveform strip.
- **Capture** — owns the recording: the platform recorder, file placement, and
  the monotonic clock card taps are stamped against. The only module touching
  the microphone.
- **Detect** — the loudness-envelope pass that turns a finished recording into
  laugh events (D7). Pure Dart over PCM: no platform API, no model, no I/O.
- **Review** — post-show: bit timeline, laugh alignment, take comparison.
- **Share** (Phase B) — upload manager (resumable, against presigned URLs),
  share-link list, QR rendering.

### The platform seam

Everything platform-specific sits behind one narrow contract, `RecordingSession`:
start and stop writing to a path, report seconds captured, report a current
amplitude, and report interruption transitions. Audio bytes never cross into
Dart — they go microphone → encoder → disk natively, and the file is read back
by Detect afterwards. What crosses the boundary is commands down and small
events up.

The two implementations use each platform's high-level recorder (D10):

| | iOS | Android |
|---|---|---|
| Recorder | `AVAudioRecorder` | `MediaRecorder` |
| Amplitude | metering (`averagePower`) | `getMaxAmplitude()` |
| Background | `audio` background mode | foreground service, microphone type |
| Interruption | audio-session interruption notifications | inferred (see R9) |

Platform facts constraining this design:

- **iOS** (verified 2026-08-20 against Apple doc JSON): App Review Guideline
  2.5.14 requires explicit consent and a clear recording indicator;
  `NSMicrophoneUsageDescription` is mandatory. Audience-recording consent is a
  jurisdiction-law matter, not App Review — onboarding carries one line telling
  the comedian to observe local law and venue rules.
- **iOS transcription is unsuitable on-device for hour-long sets**:
  SFSpeechRecognizer has a ≈1-minute network limit with unreliable
  chunked-session timestamps
  ([docs](https://developer.apple.com/documentation/speech/sfspeechrecognizer));
  [SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer)
  is iOS/iPadOS 26+ only. This is what puts transcription server-side (D2).
- **Android** (⚠ **unverified** — no authoritative source consulted yet; verify
  before the Android recorder is written): the microphone foreground-service
  type required for background capture, the API level at which it became
  mandatory, `MediaRecorder`'s AAC configuration, and whether an incoming call
  delivers an interruption callback or silently substitutes silence (R9).
  Play policy's equivalent of 2.5.14 is likewise unchecked.

## Cloudflare backend design

All limits verified 2026-08-20 against the cloudflare-docs source repo
(`production` branch; developers.cloudflare.com renders it).

### Services

- **API Worker** — small authenticated surface for the app: request upload
  (returns presigned R2 PUT), register show metadata, poll processing status,
  mint share links. Hono or plain fetch-router; no bytes flow through it
  (Worker request bodies cap at the plan limit, e.g. 100 MB — presigned-direct
  avoids the cap entirely).
- **R2** — `shows/` originals, `artifacts/` transcripts + laugh JSON + segment
  JSON, `public/` share-page audio. A 60-min 128 kbps AAC show ≈ 60 MB fits a
  single presigned PUT (5 GiB single-part cap); multipart only for WAV-scale
  files. Presigned PUTs can't enforce size — the Worker validates object size
  after the upload-complete callback.
- **Workflow `process-show`** — the pipeline orchestrator (per-step CPU to
  5 min, unlimited step wall-clock, results ≤1 MiB so artifacts live in R2 and
  steps pass keys):
  1. **probe** — read audio metadata, plan chunking.
  2. **transcribe** — time-based chunks (~1 min, cut on silence with overlap;
     never byte-sliced mid-frame) through `@cf/openai/whisper-large-v3-turbo`;
     re-offset word timestamps; stitch. Workers AI's max audio size is
     undocumented (Cloudflare's own tutorial chunks at 1 MB), so chunk size is
     a config value, found empirically. Cost ≈ $0.03/hour of audio
     ($0.0005/audio-min); ASR rate limit 720 req/min swallows a 60-chunk show.
  3. **laugh-detect** — the same loudness-envelope algorithm the client runs
     (D3, D7), over the full audio. Cheap enough to run in a Worker or the
     Container; emits laugh spans + intensity to R2.
  4. **segment** — bit boundaries from laughter peaks + embedding-similarity
     minima over the transcript (Workers AI embedding model), then an LLM pass
     (Workers AI) to adjudicate boundaries and name bits. The published
     comedy-pipeline shape (TIC-TALK; EMNLP 2021 used laughter as boundaries).
  5. **persist** — segments/takes/laugh stats into D1; artifacts already in R2.
  6. **publish** — on request, mint an unguessable share slug into D1, copy
     playable audio to `public/`.
- **ffmpeg home** — probing and chunk-cutting need ffmpeg, which Workers can't
  run, so a Container image carries it. That is now its only job.
- **D1** — `shows`, `segments`, `takes`, `laugh_events` (aggregated),
  `share_links`. Well under the 10 GB/db and 2 MB/row limits.
- **Share page** — Workers static assets (HTML/JS ≤25 MiB/file) + audio as
  HTTPS range requests straight from R2 (egress-free). Cloudflare Stream is
  explicitly not used: it rejects audio-only uploads.
- **Queues** — not in the v1 pipeline; the Workflow is triggered directly by
  the upload-complete API call. Queues enter later if fan-out (many shows at
  once) needs buffering.

### Share-link flow (the QR story)

1. Owner records a show in the app (or imports a file), uploads it.
2. Pipeline runs; owner reviews segments in the app, optionally trims/renames,
   picks the comedian's slice of the show (a show may contain several comics).
3. Owner taps "Share" → API mints `https://<share-domain>/s/<slug>` → app
   renders the QR on device → comedian scans it at the bar.
4. The share page needs no account: player, segmented set, laugh timeline.
   Slug is unguessable (128-bit); owner can revoke (row delete + `public/`
   object delete). A share link is the acquisition surface, so the page footer
   carries the store links.

### Identity, cost, privacy posture

- Phase A has no accounts. Phase B needs only a device-scoped API token
  (attestation later if abuse appears); full accounts wait until sync (Phase C).
- Cost at hobby scale is ~zero: Workers Paid ($5/mo) + pennies of Workers AI
  + R2 storage; free egress keeps share playback free.
- Recordings are the comedian's unreleased material — the privacy story from
  Phase A ("stays on your device") changes at Phase B upload, which is opt-in
  per show; the store privacy labels and policy change in the same release
  that ships upload.

## Data model (shared vocabulary)

- **Joke** — the durable unit of material (title, text, tags, callbacks).
- **Set** — an ordered list of jokes planned for a show.
- **Show** — one performance event (venue, time, audience descriptors) with one
  recording.
- **Segment** — a time span of a show's recording bound to a joke (manual tap
  in Phase A, pipeline-proposed in Phase B; provenance kept: `manual` vs
  `detected`, unknown stays absent, never zero).
- **Take** — the join of one joke across shows (what screen 2 compares).
- **LaughEvent** — a span of room noise: start, duration, intensity. It carries
  no class and no confidence, because the detector that produces it (D7) has
  neither to report.
- **ShareLink** — slug → show slice, revocable.

## Decisions

Numbered so review discussion can key on them; ids are stable, so a decision
that changes is revised in place rather than renumbered. "Recommended" = this
doc's call, reversible until code lands on it.

- **D1 (recommended): one Flutter codebase, not native per platform.** The
  product must run on iOS and Android across phone and tablet sizes, and the
  platform-specific surface is now one narrow recorder contract (above) rather
  than a shared audio pipeline — so a second native client would duplicate the
  UI, the core and the requirements harness to save nothing. Flutter also keeps
  the executable-requirements harness on Linux, which is what makes D9
  reachable.
- **D2 (recommended): iOS 17 and Android API 26 floors; transcription
  server-side.** Keeps Phase A shippable broadly. On-device ASR upgrades stay
  opportunistic, never a floor. The Android floor is provisional until the
  facts above are verified.
- **D3 (recommended): one detector, everywhere.** The same loudness-envelope
  algorithm runs on device and in the Phase B pipeline, so scores are
  comparable by construction and no calibration pass stands between recording
  and cross-show analysis. A `LaughEvent` therefore names no detector; if the
  algorithm ever versions incompatibly, that version becomes the thing events
  carry.
- **D4 (recommended): no Cloudflare Stream, no server QR.** R2 range requests
  for playback; QR rendered on device.
- **D5 (open): share-page domain** — needs the owner's domain choice; blocks
  nothing until Phase B publish.
- **D6 (open): Whisper chunk strategy fallback** — if empirical Workers AI
  limits make chunk-stitching quality unacceptable, the fallback is running
  whisper.cpp inside a Container (CPU, batch-tolerable) or
  `@cf/deepgram/nova-3` ($0.0052/min). Decide on real data in Phase B.
- **D7 (recommended): loud is a laugh.** In a comedy club, sustained room noise
  above the room's own baseline is laughter; the product does not need to tell
  laughter from applause from cheering. Detection is therefore a loudness
  envelope over PCM with a threshold and a minimum duration — a pure function,
  no model, identical on every platform. What this buys: it is deterministic
  and unit-testable against a committed audio fixture, where a classifier is a
  platform black box that can only be trusted, never asserted.
- **D8 (recommended): analysis runs after the set, not during it.** Nothing
  classifies while the microphone is live, so capture and analysis never share
  a session. This removes background-classification and thermal risk outright,
  and it is why the platform seam can be a high-level recorder.
- **D9 (recommended): no macOS CI runner until store publication.** Every lane
  — unit, logic, behavior, screen goldens and sagas — runs on Linux, which
  Flutter's golden harness supports. A macOS runner returns only for the iOS
  archive-and-upload job, whose input is a build, not a test.
- **D10 (recommended): high-level platform recorders.** With no live analysis
  (D8) nothing needs raw PCM during capture, so `AVAudioRecorder` and
  `MediaRecorder` satisfy the whole contract including amplitude metering.
  Engine-level APIs would buy live-PCM capability the product has decided it
  does not want, at the cost of substantially more native code on both
  platforms.
- **D11 (recommended): one focused golden per requirement; whole-screen
  goldens per size class.** A leaf about one element is proved by a crop of
  that element at a single reference size. Only a leaf whose claim *is* the
  screen renders whole, and only those render once per supported size class —
  so the size matrix multiplies a handful of goldens, not the spec. The
  requirements doc owns the convention's mechanics.

## Risks

- **R1 — laugh detection quality on club audio.** A loudness threshold will
  fire on anything loud: a dropped glass, a passing siren, the PA. There is no
  benchmark for this on single-mic club recordings. Mitigation: Phase A ships
  manual segmentation regardless, so a false event costs a mark on a timeline
  and never a lost bit; a labeled real-set evaluation is a Phase B step, and
  the fix for whatever it finds lives inside one pure function.
- **R2 — retired.** Was: the built-in sound classifier failing while the screen
  is locked. Nothing classifies during capture any more (D8), so the failure
  mode no longer exists. Kept as an id because review discussion keys on these.
- **R3 — Workers AI Whisper input ceiling undocumented.** Chunk size is a
  config value, found empirically; D6 is the fallback.
- **R4 — 60-min recording thermal/battery on a phone or tablet.** Much reduced
  now that nothing classifies during capture, but unmeasured on real hardware.
  Verified by a device run, not by CI.
- **R5 — store review.** Recording apps clear review routinely (24–48 h
  typical on iOS); the consent screen, indicator (2.5.14) and truthful privacy
  labels are in Phase A's scope, not bolted on.
- **R6 — golden determinism across Flutter versions.** A renderer change shifts
  text rasterization and reds every golden at once. Mitigation: pin the SDK
  version in CI and in the environment setup, and generate and verify goldens
  on Linux only.
- **R7 — the performer's own voice dominating the envelope.** If the comedian
  or the PA is louder than the room, the threshold tracks the wrong signal.
  Mitigation: the fix lives inside Detect and changes nothing architecturally,
  so it is deferred deliberately until real recordings say whether it is real.
- **R8 — OEM battery managers force-stopping the Android foreground service**
  during a long set. Device-verified, not CI-verified.
- **R9 — Android interruption semantics.** Under the shared-microphone policy a
  privileged app may take the input while `MediaRecorder` keeps running and
  records silence, in which case no callback marks the gap and requirement 6.6
  must be satisfied by inference rather than by an event. Unverified; it
  decides how much of the Android recorder is bespoke.
