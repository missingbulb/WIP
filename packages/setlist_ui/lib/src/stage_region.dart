import 'package:flutter/widgets.dart';

/// The parts of the stage screen a requirement can be about.
///
/// A leaf that asserts one element is proved by a picture of that element, not
/// by the whole screen: a reviewer approving a spec should be looking at the
/// thing the line claims. The screen tags its own regions, so a case can ask
/// for one by name without knowing any coordinates.
enum StageRegion {
  /// The recording dot and the room's name.
  venue,

  /// Countdown, elapsed and planned, together.
  clocks,
  pacingBar,

  /// The whole current-joke panel.
  currentJoke,

  /// The joke's title and how long it has been running.
  jokeTitleRow,
  jokeBody,
  jokeTags,
  laughStrip,
  segmentMode,

  /// "SET LIST · n / n".
  setListCount,

  /// The told / live / queued key.
  setListKey,

  /// The nine cards.
  grid,
}

extension StageRegionKey on StageRegion {
  /// The key the screen tags this region with, and the harness finds it by.
  ///
  /// A key rather than the original's layout-preference plumbing: Flutter can
  /// measure any keyed widget after a pump, so the screen needs to carry
  /// nothing at runtime beyond the tag itself.
  Key get key => ValueKey(this);
}
