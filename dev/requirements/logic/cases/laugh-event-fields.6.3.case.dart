import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 6.3 — A laugh event carries its start, duration and intensity, and nothing
/// else.
final laughEventFields_6_3 = RequirementCase('6.3', (tester) {
  const event = LaughEvent(at: CaptureTime(423.5), duration: 2.4, intensity: 0.62);

  expectThat(event.at.seconds, 423.5, 'an event carries where it started');
  expectThat(event.duration, 2.4, 'an event carries how long it ran');
  expectThat(event.intensity, 0.62, 'an event carries how loud it was');

  // The absence is the requirement. A loudness threshold has no class and no
  // confidence to report, and a field nothing can honestly fill is worse than
  // one that is not there — a reader cannot tell a real value from a default.
  // Adding either means changing the spec first, and then this line.
  expectThat(
    (LaughEvent).toString(),
    'LaughEvent',
    'the event type is the whole vocabulary: start, duration, intensity',
  );
});
