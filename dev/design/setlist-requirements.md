# Set list — requirements

iPad app for comedians to manage and analyse live material. Everything below was specified across this conversation; the design notes at the end are proposals, not requirements.

---

## Screen 1 — Stage mode (live)

**Purpose:** used on stage during a set.

### Jokes as cards
- Each joke is a card, identified by a keyword or short title.
- Tapping a card marks the start of that joke.
- A tapped card expands to show additional optional text — alternate tags, callbacks, delivery notes.

### Current joke (top of screen)
- The joke currently being performed occupies the top region.
- Crucial setups are highlighted within the joke text.
- Joke text is the dominant element on the screen.

### Set list (bottom of screen)
- 3-column grid of large boxes.
- Must be readable at a glance during a live show.
- Jokes already told are coloured differently from queued jokes.
- No per-bit laugh count on this screen.

### Recording and transcription
- Recording runs continuously through the set.
- Transcription runs alongside it.
- Laugh peaks are detected and aligned with the transcript text.

### Timer
- A timer is present as a helper, not as the dominant element.
- Counts down to the end of the set.

### Segment mode toggle
- Standard iOS switch.
- Off: **Manual switch** — the comedian taps cards to mark segment boundaries.
- On (green): **Autodetect bits** — segments are inferred automatically.
- No explanatory text beside it.

### Layout
- Portrait orientation, true iPad proportions (3:4).
- Fits on one screen without scrolling.

---

## Screen 2 — Joke analysis

**Purpose:** reviewing material after the fact.

- For a given joke, show several recordings of it side by side.
- Show laugh peaks for each recording.
- Highlight anomalies — takes that deviate from the norm.
- Navigate from a single joke recording out to the whole show, viewed as a chain of jokes, to see what did and didn't land.
- Show metadata for each show: time, location, audience description.
- One screen.

---

## Visual direction

- Dark UI, appropriate for a stage environment.
- No pastel colours.
- Not bland — a distinct visual identity.
- Mockups presented inside an iPad frame at correct screen proportions.

---

## Proposals (not yet decided)

These came up during design and are still open:

**Autodetect behaviour**
- What a card tap means in autodetect mode: correction, override, or read-only. Correction degrades most gracefully.
- Autodetect needs a confidence floor — below it, show the last confirmed joke rather than guess, and log the ambiguity for post-show cleanup.
- The toggle may belong in pre-show setup rather than the live screen, freeing vertical space.

**Laugh detection**
- On-device audio classification vs. amplitude thresholding. Amplitude is trivial but confuses applause, heckles and dropped glasses with laughter.

**Audience description**
- Freeform text vs. structured fields (size, seated/standing, time, alcohol, corporate/public). Structured is required for queries like "underperforms with seated dinner crowds".

**Timer behaviour**
- Silent until a threshold, then orange, then red.
- Mirror the club's own light cues, configured per venue.
- Pacing-based: goes orange when remaining time drops below the closer's average length.

**Live waveform**
- Possibly reduce to a single bar that lights while laughter is above threshold, dims when it's safe to speak — the one thing genuinely hard to judge from behind a mic.

**Grid density**
- 9 cards at 3-across is near the readability limit. 6 larger cards with a page-flip is the alternative.

**Joke text size**
- Should be user-configurable; every comic holds the iPad at a different distance.
