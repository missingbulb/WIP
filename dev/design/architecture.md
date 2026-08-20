# Set list — architecture & system design

The iPad app for comedians (working title "Set list"; repo working name
Claudinite) and its Cloudflare backend. Product behavior is specified by
[`setlist-requirements.md`](setlist-requirements.md) (the owner's screen-level
requirements) and illustrated by
[`mockups/setlist-ipad-mockups.html`](mockups/setlist-ipad-mockups.html); this
document is the system shape those requirements run on. The numbered executable
spec will live under `dev/requirements/` once authored — this doc does not
duplicate requirement text.

Owner constraints this design serves:

1. **Ship to the App Store ASAP** — simplified, client-only flows are acceptable
   first.
2. **A backend process outside the app**: ingest a full-show recording, run
   segmentation + laugh detection offline/batch, and hand the comedian a link to
   their segmented show as a QR code.
3. **Cloudflare is the cloud platform.**

## System context

```
┌────────────────────────┐         ┌──────────────────────────────────┐
│ iPad app (SwiftUI)     │         │ Cloudflare                        │
│  stage mode · record   │ upload  │  Worker API ── Workflow pipeline  │
│  laugh detect · review │────────▶│  R2 audio/artifacts   D1 metadata │
│  QR display            │◀────────│  Workers AI (Whisper, embeddings, │
└────────────────────────┘ results │   LLM)   Container (laugh model)  │
                                   │  share page (static assets + R2)  │
          ┌──────────────┐  HTTPS  └──────────────────────────────────┘
          │ Comedian's    │◀──────────────┘
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

### Phase A — client-only MVP (App Store submission target)

No backend, no accounts, everything on device. This is deliberately the
BitBinder-style "100% local, works offline" posture — a trust feature for
material-protective comedians, not just a shortcut.

- **Set list management**: jokes as cards, set builder, the stage-mode screen
  from the mockups (current joke, pacing bar, countdown, 3×3 grid).
- **Recording**: continuous AVAudioEngine capture through the set, AAC on disk,
  background-audio entitlement so a locked screen keeps recording.
- **Laugh detection, live**: SoundAnalysis `SNClassifySoundRequest` with the
  built-in classifier tapping the same input node — `laughter` / `applause` /
  `cheering` classes with confidences, stored as timestamped events beside the
  audio. RMS energy inside laughter-classified windows is the intensity score.
- **Segmentation, manual**: card taps mark bit boundaries (the mockups' "Manual
  switch" mode). Autodetect is explicitly out of Phase A.
- **Review**: per-show timeline of laugh events aligned to bit boundaries; the
  joke-analysis screen fed by manual boundaries + laugh events only (no
  transcript yet — transcript-dependent affordances stay hidden).
- **No transcription in Phase A.** On-device long-form ASR either demands
  iPadOS 26 (SpeechAnalyzer) or a ~1.6 GB WhisperKit model download; both cost
  ship-speed. Transcripts arrive with the backend in Phase B.

### Phase B — Cloudflare batch pipeline + QR share

The owner-described backend flow: record a full show (multiple comedians or a
full set), upload, process offline, hand out QR links.

- Upload from the app to R2 (presigned, direct).
- Pipeline (Workflow): transcribe → laugh-detect → segment → persist → publish
  share link.
- Share page in the browser: audio player streaming from R2, segmented set with
  laugh timeline, per-bit jump links. QR code rendered **on device** from the
  share URL (CoreImage `CIQRCodeGenerator`) — no server QR endpoint.

### Phase C — the analysis product

Cross-show joke analysis (the mockups' screen 2 at full power): takes of one
joke side by side, anomaly flags, room metadata queries. Autodetect-bits live
mode, informed by Phase B's segmentation quality. Sync of the on-device library
through the same backend. Designed later, on Phase B's data.

## iPad app design

SwiftUI, iPadOS-native. Modules named by responsibility:

- **Library** — jokes, sets, shows; SwiftData/SQLite store; everything
  user-deletable lives in the app's container.
- **Stage** — the live screen: set list state machine (queued → live → told),
  countdown, pacing bar. Reads Capture's live laugh feed for the waveform strip.
- **Capture** — one AVAudioEngine session owning: file write (AAC), the
  SoundAnalysis tap, and timestamp bookkeeping (card taps + laugh events on one
  monotonic clock). The only module touching the microphone.
- **Review** — post-show: bit timeline, laugh alignment, take comparison.
- **Share** (Phase B) — upload manager (background `URLSession` against
  presigned URLs, resumable), share-link list, QR rendering.

Platform facts constraining this design (verified 2026-08-20 against Apple doc
JSON unless noted):

- Built-in classifier identifier requires iOS/iPadOS 15+
  ([SNClassifySoundRequest](https://developer.apple.com/documentation/soundanalysis/snclassifysoundrequest));
  live-input classification off an engine tap is Apple's documented usage
  ([sample](https://developer.apple.com/documentation/SoundAnalysis/classifying-live-audio-input-with-a-built-in-sound-classifier)).
- SFSpeechRecognizer is unsuitable for hour-long sets (≈1-min network limit;
  chunked-session workarounds with unreliable timestamps —
  [docs](https://developer.apple.com/documentation/speech/sfspeechrecognizer));
  [SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer)
  is iOS/iPadOS 26+ only.
- App Review Guideline 2.5.14: explicit consent + a clear recording indicator;
  `NSMicrophoneUsageDescription` mandatory. Audience-recording consent is a
  jurisdiction-law matter, not App Review — onboarding carries one line telling
  the comedian to observe local law and venue rules.
- A forum-reported failure of the built-in classifier while backgrounded
  ([thread 811582](https://developer.apple.com/forums/thread/811582)) is
  unverified — R2 (risks, below) makes it the first device spike.

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
  3. **laugh-detect** — Container (CPU; up to 4 vCPU / 12 GiB) running the
     Gillick `laughter-detection` model over the full audio; batch runtime is
     acceptable, no GPU exists for customer containers, and Workers AI takes no
     custom models. Emits laugh spans + intensity to R2.
  4. **segment** — bit boundaries from laughter peaks + embedding-similarity
     minima over the transcript (Workers AI embedding model), then an LLM pass
     (Workers AI) to adjudicate boundaries and name bits. The published
     comedy-pipeline shape (TIC-TALK; EMNLP 2021 used laughter as boundaries).
  5. **persist** — segments/takes/laugh stats into D1; artifacts already in R2.
  6. **publish** — on request, mint an unguessable share slug into D1, copy
     playable audio to `public/`.
- **ffmpeg home** — probing and chunk-cutting need ffmpeg, which Workers can't
  run; both live in the same Container image as the laugh detector (one image,
  one deploy).
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
   carries the App Store link.

### Identity, cost, privacy posture

- Phase A has no accounts. Phase B needs only a device-scoped API token
  (App Attest later if abuse appears); full accounts wait until sync (Phase C).
- Cost at hobby scale is ~zero: Workers Paid ($5/mo) + pennies of Workers AI
  + R2 storage; free egress keeps share playback free.
- Recordings are the comedian's unreleased material — the privacy story from
  Phase A ("stays on your iPad") changes at Phase B upload, which is opt-in
  per show; the App Store privacy labels and policy change in the same release
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
- **LaughEvent** — classified span with class, confidence, intensity.
- **ShareLink** — slug → show slice, revocable.

## Decisions

Numbered so review discussion can key on them. "Recommended" = this doc's
call, reversible until code lands on it.

- **D1 (recommended): SwiftUI-native client, not Flutter.** The product is
  built on first-party audio APIs (AVAudioEngine tap shared by recorder and
  SoundAnalysis, background audio, later SpeechAnalyzer); bridging those
  through platform channels costs more than Flutter's golden-test harness
  precedent saves. The executable-requirements harness gets built for Swift
  (snapshot kinds via the simulator's deterministic renderer).
- **D2 (recommended): minimum iPadOS 17, transcription server-side.** Keeps
  Phase A shippable to every current iPad; SpeechAnalyzer (26+) becomes an
  opportunistic on-device upgrade later, not a floor.
- **D3 (recommended): two laugh detectors, calibrated later.** SoundAnalysis
  live on device (zero integration cost), Gillick in the Container for batch.
  Their scores are not comparable until a calibration pass on real recordings
  exists (risks, R1); cross-show analytics (Phase C) must not mix uncalibrated
  sources — the event rows carry their detector.
- **D4 (recommended): no Cloudflare Stream, no server QR.** R2 range requests
  for playback; CoreImage QR on device.
- **D5 (open): share-page domain** — needs the owner's domain choice; blocks
  nothing until Phase B publish.
- **D6 (open): Whisper chunk strategy fallback** — if empirical Workers AI
  limits make chunk-stitching quality unacceptable, the fallback is running
  whisper.cpp inside the existing Container (CPU, batch-tolerable) or
  `@cf/deepgram/nova-3` ($0.0052/min). Decide on real data in Phase B.

## Risks

- **R1 — laugh detection quality on club audio.** No published benchmark of
  any detector on single-mic club recordings; Gillick 2021 exists precisely
  because noise causes false positives. Mitigation: Phase A ships manual
  segmentation regardless; a labeled real-set evaluation is a Phase B step.
- **R2 — SoundAnalysis while screen-locked.** Forum-reported failure in
  background. Mitigation: first device spike; fallback is recording live +
  running the same classifier over the file immediately post-set on device
  (minutes, not live — stage-mode waveform degrades gracefully).
- **R3 — Workers AI Whisper input ceiling undocumented.** Chunk size is
  config, found empirically; D6 is the fallback.
- **R4 — 60-min concurrent record+classify thermal/battery on iPad.**
  Adjacent evidence positive, direct evidence absent; same spike as R2.
- **R5 — App Review.** Recording apps clear review routinely (24–48 h
  typical); consent screen + indicator (2.5.14) and truthful privacy labels
  are in Phase A's scope, not bolted on.
