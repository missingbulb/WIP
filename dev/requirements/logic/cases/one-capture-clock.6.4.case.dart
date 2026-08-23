import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 6.4 — Laugh events and card taps are ordered on one monotonic clock, so
/// their interleaving is well defined even across a wall-clock change.
final oneCaptureClock_6_4 = RequirementCase('6.4', (tester) {
  final ordered = timeline(
    taps: [
      TapEvent(at: const CaptureTime(10), jokeId: 'van'),
      TapEvent(at: const CaptureTime(0), jokeId: 'opener'),
      TapEvent(at: const CaptureTime(8), jokeId: 'airport'),
    ],
    laughs: [
      const LaughEvent(at: CaptureTime(4), duration: 2, intensity: 0.6),
      const LaughEvent(at: CaptureTime(8), duration: 1, intensity: 0.9),
    ],
  );

  expectThat(
    [for (final entry in ordered) entry.at.seconds],
    [0.0, 4.0, 8.0, 8.0, 10.0],
    'everything sorts on the one clock',
  );

  // At an equal stamp the tap comes first: a tap is the boundary the laughs
  // after it belong to, so the other order files a bit's opening laugh under
  // the bit before it.
  expectTrue(
    ordered[2] is TapEvent && ordered[3] is LaughEvent,
    'a tap sorts before a laugh stamped at the same instant',
  );
});
