import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 5.5 — Tapping a told card re-opens it as live and opens a second segment for it,
/// leaving its first segment intact.
final tapToldCard_5_5 = RequirementCase('5.5', (tester) {
  final stage = StageModel(
    jokes: [
      Joke(id: 'opener', title: 'Opener', body: ''),
      Joke(id: 'van', title: "Dad's van", body: ''),
    ],
    plannedLength: const Duration(minutes: 20),
  );

  stage.tapCard(jokeId: 'van', at: const CaptureTime(0));
  stage.tapCard(jokeId: 'opener', at: const CaptureTime(60));

  // The callback lands, so the comedian goes back to the van.
  stage.tapCard(jokeId: 'van', at: const CaptureTime(200));

  final vanSegments = [for (final s in stage.segments) if (s.jokeId == 'van') s];
  expectThat(vanSegments.length, 2, 'the van has a second segment');
  expectThat(vanSegments.first.start, const CaptureTime(0), 'its first starts where it did');
  expectThat(vanSegments.first.end, const CaptureTime(60), 'and ends where it did');
  expectAbsent(vanSegments.last.end, 'while the new one is open');
  expectThat(stage.liveJokeId, 'van', 'and the van is live again');
});
