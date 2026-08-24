-- The pipeline's record of a show: what was uploaded, what it was cut into, and
-- who can see it. The audio and the artifacts themselves live in R2; a row here
-- holds the key, never the bytes.

CREATE TABLE shows (
  id TEXT PRIMARY KEY,
  device_id TEXT NOT NULL,
  title TEXT,
  venue TEXT,
  -- Absent until the recorder or the probe knows it. Never zero: a show whose
  -- duration is unknown is not a show of no length.
  performed_at TEXT,
  duration_seconds REAL,
  audio_key TEXT NOT NULL,
  byte_size INTEGER,
  content_type TEXT NOT NULL,
  -- awaiting-upload | processing | ready | failed
  status TEXT NOT NULL,
  failure TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX shows_by_device ON shows (device_id, created_at);

CREATE TABLE segments (
  id TEXT PRIMARY KEY,
  show_id TEXT NOT NULL REFERENCES shows (id) ON DELETE CASCADE,
  ordinal INTEGER NOT NULL,
  start_seconds REAL NOT NULL,
  end_seconds REAL NOT NULL,
  title TEXT,
  transcript TEXT,
  -- manual | detected. Kept because a comedian trusts their own boundary more
  -- than the pipeline's, and Phase C compares takes across both.
  provenance TEXT NOT NULL,
  joke_id TEXT
);
CREATE UNIQUE INDEX segments_by_show ON segments (show_id, ordinal);

CREATE TABLE laugh_events (
  id TEXT PRIMARY KEY,
  show_id TEXT NOT NULL REFERENCES shows (id) ON DELETE CASCADE,
  at_seconds REAL NOT NULL,
  duration_seconds REAL NOT NULL,
  intensity REAL NOT NULL
);
CREATE INDEX laugh_events_by_show ON laugh_events (show_id, at_seconds);

CREATE TABLE share_links (
  slug TEXT PRIMARY KEY,
  show_id TEXT NOT NULL REFERENCES shows (id) ON DELETE CASCADE,
  -- The slice of the show this link exposes: one comedian's set out of a
  -- night. Absent means the whole show.
  from_seconds REAL,
  to_seconds REAL,
  public_key TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE INDEX share_links_by_show ON share_links (show_id);
