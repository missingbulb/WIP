import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/fake_world.dart';
import '../../shared/requirement_case.dart';

/// 5.6 — Card taps are stamped on the capture clock, so a tap's timestamp is
/// comparable with a laugh event's without conversion.
final tapOnCaptureClock_5_6 = RequirementCase('5.6', (tester) async {
  final session = FakeRecordingSession();
  final capture = CaptureCoordinator(session: session, containerPath: '/container');
  final stage = StageModel(
    jokes: [Joke(id: 'airport', title: 'Airport security', body: '')],
    plannedLength: const Duration(minutes: 20),
  );

  await capture.startShow('show-1');
  session.recordSeconds(507);

  stage.tapCard(jokeId: 'airport', at: capture.now);

  expectThat(
    stage.segments.single.start.seconds,
    507,
    'the tap is stamped with recorded seconds, not wall time',
  );

  // The same clock a laugh event is stamped against, so the two interleave
  // without anything having to convert between them.
  final ordered = timeline(
    taps: [TapEvent(at: capture.now, jokeId: 'airport')],
    laughs: [const LaughEvent(at: CaptureTime(508.2), duration: 1.4, intensity: 0.7)],
  );
  expectThat(ordered.first.at.seconds, 507, 'and sorts against laughs directly');
});
