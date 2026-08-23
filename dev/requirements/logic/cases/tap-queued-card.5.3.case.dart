import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 5.3 — Tapping a queued card ends the live joke's segment and opens a segment for
/// the tapped joke at the same instant.
final tapQueuedCard_5_3 = RequirementCase('5.3', (tester) {
  final stage = StageModel(
    jokes: [
      Joke(id: 'opener', title: 'Opener', body: ''),
      Joke(id: 'van', title: "Dad's van", body: ''),
    ],
    plannedLength: const Duration(minutes: 20),
  );

  stage.tapCard(jokeId: 'opener', at: const CaptureTime(0));
  final outcome = stage.tapCard(jokeId: 'van', at: const CaptureTime(90));

  expectThat(outcome, const TapSwitched('van'), 'the tapped joke goes live');
  expectThat(stage.liveJokeId, 'van', 'and is the one running');
  // The same instant for both boundaries, so no gap belongs to neither bit.
  expectThat(stage.segments.first.end, const CaptureTime(90), 'the live segment closes');
  expectThat(stage.segments.last.start, const CaptureTime(90), 'as the next one opens');
  expectAbsent(stage.segments.last.end, 'and the new segment is still open');
});
