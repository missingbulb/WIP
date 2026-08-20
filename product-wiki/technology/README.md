# technology

Technology Claudinite could build on: comedy-context audio recording,
transcription, audio analysis (e.g. detecting laughs), and text segmentation
of transcripts into distinct bits.

## Key insights

- Apple's built-in sound classifier already has laughter, applause and cheering classes — on-device laugh detection is free.
- SFSpeechRecognizer can't do a 60-minute set; the first-party long-form API (SpeechAnalyzer) needs iOS 26; WhisperKit is the fallback.
- Workers AI hosts Whisper with word timestamps at ~$0.03 per hour-long set — but max audio size is undocumented; ~1 MB chunking is mandatory.
- Cloudflare Containers are GA but CPU-only — fine for the small OSS laughter detector; custom models can't run on Workers AI.
- Published comedy pipelines (TIC-TALK, EMNLP 2021) already do exactly this: laughter peaks + embedding topic shifts as bit boundaries.
- Cloudflare Stream rejects audio-only uploads — serve show audio as range requests straight from R2 (free egress).
- Amplitude thresholding alone is untrustworthy; classify the sound, then use energy within laugh windows as intensity.

## Recording (comedy context)

Provenance note: Cloudflare claims below were verified verbatim against the
official docs *source* (the `cloudflare/cloudflare-docs` GitHub repo, `production`
branch — developers.cloudflare.com itself was egress-blocked); Apple availability
claims against Apple's documentation JSON endpoints. Items marked *snippet only*
carry publisher attribution without an opened page. Retrieved 2026-08-20.

- **Live capture + classification is the designed usage**: Apple's sample
  "Classifying Live Audio Input with a Built-in Sound Classifier" drives
  `SNAudioStreamAnalyzer` from an `AVAudioEngine` input-node tap — the same live
  stream the recorder writes to disk from
  ([developer.apple.com](https://developer.apple.com/documentation/SoundAnalysis/classifying-live-audio-input-with-a-built-in-sound-classifier)).
- **Background caveat**: one forum report says the built-in classifier fails in the
  background with `SNErrorCode.operationFailed`
  ([developer.apple.com/forums/thread/811582](https://developer.apple.com/forums/thread/811582),
  snippet only) — a set-recording app will be screen-locked, so this needs a device
  test early.
- **Thermal/battery for a 60-min concurrent stack**: nothing citable proves the
  exact combo. Adjacent data points (all snippet only): <5% battery per 30-min
  WhisperKit session on iPhone 15, no thermal throttling over 15-min sessions
  ([forasoft.com](https://www.forasoft.com/blog/article/speech-recognition-with-neural-networks-on-ios-1621));
  Neural Engine draws roughly half GPU power sustained
  ([rockyshikoku.medium.com](https://rockyshikoku.medium.com/iphone-on-device-llm-the-gpu-wins-the-sprint-the-neural-engine-wins-the-marathon-ce34839774a2)).
  The safe shape: record + laugh-classify live (cheap), defer full transcription to
  post-set or the backend.

## Transcription

- **SFSpeechRecognizer is the wrong tool for a set**: Apple's docs give network
  recognition a ~one-minute audio limit; on-device mode (iOS 13+) removes it, but
  community experience shows ~50-min continuous recognition only via chunked
  sessions with segment timestamps erratically resetting
  ([developer.apple.com/documentation/speech/sfspeechrecognizer](https://developer.apple.com/documentation/speech/sfspeechrecognizer);
  forums threads [128722](https://developer.apple.com/forums/thread/128722),
  [131940](https://developer.apple.com/forums/thread/131940), snippet only).
- **SpeechAnalyzer / SpeechTranscriber** is the first-party long-form answer —
  but requires iOS/iPadOS **26.0+** (verified via Apple doc JSON:
  [speechanalyzer](https://developer.apple.com/documentation/speech/speechanalyzer),
  [speechtranscriber](https://developer.apple.com/documentation/speech/speechtranscriber)).
  Third-party reporting claims ~2× faster than Whisper Large V3 Turbo
  ([callstack.com](https://www.callstack.com/blog/on-device-speech-transcription-with-apple-speechanalyzer),
  [argmaxinc.com](https://www.argmaxinc.com/blog/apple-and-argmax); snippet only).
- **WhisperKit** (Argmax, Swift/Core ML on the Neural Engine): sub-100 ms streaming
  latency reported on iPhone 15 Pro; large-v3-turbo ~1.6 GB on disk
  ([arxiv.org/pdf/2507.10860](https://arxiv.org/pdf/2507.10860), snippet only).
  Raw Whisper word timestamps are known-inaccurate; WhisperX forced alignment is the
  standard server-side fix ([arxiv.org/pdf/2303.00747](https://arxiv.org/pdf/2303.00747),
  snippet only).
- **Server-side on Workers AI**: `@cf/openai/whisper` ($0.0005/audio-min) emits
  `words[] {word, start, end}` + VTT; `@cf/openai/whisper-large-v3-turbo` (same
  price) emits segments with nested words, VAD filtering, and supports async
  batch; `@cf/deepgram/nova-3` ($0.0052/audio-min) is a hosted alternative. Free
  tier 10,000 Neurons/day ≈ 3.5 h of turbo audio; a 60-min set ≈ **$0.03** paid
  (verified from `workers-ai-models/whisper*.json` + `workers-ai/platform/pricing.mdx`
  in cloudflare-docs).
- **Max audio size is officially undocumented**: Cloudflare's own tutorial chunks at
  1 MB "to overcome memory and execution time limitations"; community reports
  failures ~2 MB; docs issue #17916 confirms the gap. Plan for time-based chunking
  with timestamp re-offsetting, not byte-slicing (mid-frame MP3 cuts). ASR rate
  limit 720 req/min — a 60-chunk show fits trivially (verified from cloudflare-docs
  limits source; community thread snippet only).
- No citable benchmark of any of these on noisy comedy-club audio; nearest signal:
  Whisper v3 Turbo was lowest-WER on a 2026 noisy-conditions medical benchmark
  (PMC12628192, snippet only).

## Audio analysis (laughs)

- **On-device is free**: `SNClassifySoundRequest`'s built-in classifier (iOS 15+ for
  the v1 identifier) recognizes 300+ classes including `laughter`,
  `baby_laughter`, `giggling`, `applause`, `cheering`, `crowd` (availability
  verified via Apple doc JSON:
  [snclassifysoundrequest](https://developer.apple.com/documentation/soundanalysis/snclassifysoundrequest),
  [snclassifieridentifier](https://developer.apple.com/documentation/soundanalysis/snclassifieridentifier);
  class list snippet only —
  [swiftjectivec.com](https://www.swiftjectivec.com/sound-analysis-framework-built-in-model/)).
  Larger `windowDuration` = more accurate but less time-precise; exact numeric
  bounds unverified.
- **General audio-event models** (AudioSet, all with Laughter/Applause classes;
  snippet only): YAMNet (MobileNet-v1, mAP 0.306, phone-friendly TFLite —
  [github.com/tensorflow/models](https://github.com/tensorflow/models/tree/master/research/audioset/yamnet)),
  PANNs CNN14 (mAP 0.439 — [arxiv.org/abs/1912.10211](https://arxiv.org/abs/1912.10211)),
  AST (mAP 0.485 ensemble — [arxiv.org/pdf/2104.01778](https://arxiv.org/pdf/2104.01778)).
- **Purpose-built**: `jrgillick/laughter-detection` — the standard OSS detector,
  PyTorch, retrained per "Robust Laughter Detection in Noisy Environments"
  (Interspeech 2021) precisely to cut background-noise false positives; small,
  CPU-friendly ([github.com/jrgillick/laughter-detection](https://github.com/jrgillick/laughter-detection),
  [Gillick 2021 PDF](https://people.ischool.berkeley.edu/~kimiko/papers/Gillick.2021.Interspeech.pdf);
  snippet only).
- **Whisper-AT** emits AudioSet tags alongside transcription — one model doing
  transcript + laughter server-side; used by the TIC-TALK comedy pipeline at 0.8 s
  laughter resolution ([arxiv.org/pdf/2603.21803](https://arxiv.org/pdf/2603.21803),
  Whisper-AT arXiv 2307.03183; snippet only).
- **Amplitude thresholding alone is untrustworthy**: no citable benchmark of pure
  energy-thresholding for laughter was found; the reasoned failure modes (applause,
  cheers, heckles, glassware, varying PA level, laughter overlapping the next line)
  are corroborated by AudioSet keeping Laughter/Applause/Cheering as distinct
  classes and by Gillick 2021's noise-false-positive motivation. Practical hybrid:
  classifier for the class decision, RMS energy inside laughter-classified windows
  as the intensity score.

## Text segmentation

- **Comedy-specific precedent exists** (snippet only): TIC-TALK — BERTopic
  embedding segmentation at ~60 s granularity + Whisper-AT laughter at 0.8 s —
  essentially this product's pipeline as a research database
  ([arxiv.org/pdf/2603.21803](https://arxiv.org/pdf/2603.21803)); "So You Think
  You're Funny?" (EMNLP 2021) segmented shows into clips using audience laughter as
  boundaries and laughter loudness as the rating label
  ([aclanthology.org](https://aclanthology.org/2021.emnlp-main.789.pdf)).
- **General techniques** (snippet only): TextTiling (Hearst 1997) similarity
  minima; BertSeg embedding variants
  ([arxiv.org/pdf/2106.12978](https://arxiv.org/pdf/2106.12978)); TreeSeg for long
  transcripts (arXiv 2407.12028); Spotify's PODTILE LLM auto-chaptering — the
  closest production analogue, chapter titles ≈ bit titles (arXiv 2410.16148).
- **Synthesis**: laughter peaks as candidate bit boundaries (a bit typically ends
  at a big laugh followed by a topic shift) + embedding-similarity minima on the
  transcript + an LLM pass to name bits and adjudicate boundaries — the TIC-TALK
  shape.

## Cloudflare batch pipeline (platform facts)

All verified verbatim from the cloudflare-docs source (retrieved 2026-08-20)
unless marked snippet only:

- **Containers GA** (changelog 2026-04-13, snippet only): up to 4 vCPU / 12 GiB /
  20 GB disk per instance; billed per 10 ms active; **no GPU for customer
  containers** (reviews, snippet only) — CPU inference of Gillick's model on a
  60-min show is fine for batch. Workers AI accepts **no custom models** (LoRA
  adapters on hosted bases only).
- **Workers**: 128 MB memory per isolate; CPU 30 s default, configurable to 5 min
  (Paid); request body capped by plan (100 MB Free/Pro) — so uploads must go
  **presigned-URL-direct to R2**, not through a Worker.
- **R2**: 5 GiB single-part PUT (a 60-min 128 kbps set ≈ 60 MB fits in one),
  multipart to ~5 TiB, egress free; presigned PUTs can't enforce a max size —
  validate after upload (community, snippet only).
- **Queues**: 128 KB messages (pass R2 keys), consumer 15 min wall / 5 min CPU.
- **Workflows** (GA Apr 2025): per-step CPU to 5 min, unlimited wall-clock per
  step, step results ≤1 MiB (store transcripts in R2), `step.sleep` to 365 days —
  the right orchestrator for upload → transcribe → laugh-detect → segment → publish.
- **D1**: 10 GB/db (Paid), 2 MB max row — fine for shows/bits/share metadata.
- **Stream takes no audio-only uploads** (video required; community + Stream FAQ,
  snippet only) — serve playback as HTTPS range requests on R2 objects.
- **QR codes are trivial**: official Workers tutorial exists, but on-device
  generation from the share URL (CoreImage `CIQRCodeGenerator`) needs no server
  code at all.
- **App Store shipping facts**: App Review typically 24–48 h (live trackers read
  ~15–17 h mid-2026, spikes to days; runway.team, snippet only); internal
  TestFlight (≤100 testers) has **no Beta App Review** — builds land in minutes;
  `NSMicrophoneUsageDescription` mandatory; Guideline 2.5.14 requires explicit
  consent + a visible recording indicator; audience-recording consent is a local
  two-party-consent *law* question, not an App Review one (developer.apple.com,
  snippet only).

## Sources

Verified-source files (downloaded and read 2026-08-20): `cloudflare/cloudflare-docs`
repo, `production` branch — `workers-ai-models/whisper*.json`,
`workers-ai/platform/{pricing,limits}.mdx`, `workers/platform/limits.mdx`,
`queues/platform/limits.mdx`, `workflows/reference/limits.mdx`,
`r2/platform/limits.mdx`, `d1/platform/limits.mdx`,
`containers/{pricing,instance-types}` partials; Apple documentation JSON for
SoundAnalysis and Speech symbols (URLs inlined above). Snippet-only sources are
marked inline beside each claim; developers.cloudflare.com and several publisher
pages were egress-blocked in the research environment — page-level verification of
snippet-only items needs a human or an unblocked environment.

## Open questions

- Real Workers AI Whisper per-request audio ceiling (docs silent; community says
  ~1–2 MB) and whether the async queue path raises it — verify from an unblocked
  environment.
- Is requiring iPadOS 26 acceptable for target users (unlocks SpeechAnalyzer)?
  Otherwise WhisperKit adds a ~1.6 GB model download.
- No published benchmark of any laughter detector on comedy-club audio (PA speech
  bleeding into crowd mic) — needs an evaluation on a real recorded set.
- Does the built-in SoundAnalysis classifier run while backgrounded/screen-locked
  during a recording session? (Forum-reported failure; needs a device test.)
- Thermal/battery for the full 60-min record+classify+transcribe stack on iPad —
  needs an empirical spike.
- Whisper chunk-boundary handling: time-based segmentation with overlap +
  timestamp stitching vs. Deepgram nova-3 (which may take longer inputs —
  unverified).
- Exact `windowDuration` bounds of the built-in classifier v1.

## Growth log

- **2026-08-20** — seeded skeleton at Claudinite adoption; no research yet.
- **2026-08-20** — first research pass (web mode; Cloudflare/Apple numbers
  verified against the cloudflare-docs source repo and Apple doc JSON, the rest
  snippet-only under an egress block): filled all four sections — on-device
  recording/classification, transcription options and their hard version limits,
  laugh-detection models, comedy-specific segmentation precedent, and the verified
  Cloudflare batch-pipeline limits; rewrote Key insights; replaced seed open
  questions with the pass's concrete unknowns.
