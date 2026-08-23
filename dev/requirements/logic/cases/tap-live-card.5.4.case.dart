import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 5.4 — Tapping the live card changes nothing and opens no zero-length segment.
final tapLiveCard_5_4 = RequirementCase('5.4', (tester) {
  final stage = StageModel(
    jokes: [
      Joke(id: 'opener', title: 'Opener', body: ''),
      Joke(id: 'van', title: "Dad's van", body: ''),
    ],
    plannedLength: const Duration(minutes: 20),
  );

  stage.tapCard(jokeId: 'opener', at: const CaptureTime(0));

  final outcome = stage.tapCard(jokeId: 'opener', at: const CaptureTime(30));

  expectThat(outcome, const TapIgnored(), 'the tap is ignored');
  expectThat(stage.segments.length, 1, 'no second segment is opened');
  expectAbsent(stage.segments.single.end, 'and the one that is open stays open');
  expectThat(stage.liveJokeId, 'opener', 'the same joke is still live');
});
