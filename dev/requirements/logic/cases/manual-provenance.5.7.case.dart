import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 5.7 — Every segment opened by a card tap records `manual` provenance.
final manualProvenance_5_7 = RequirementCase('5.7', (tester) {
  final stage = StageModel(
    jokes: [
      Joke(id: 'opener', title: 'Opener', body: ''),
      Joke(id: 'van', title: "Dad's van", body: ''),
    ],
    plannedLength: const Duration(minutes: 20),
  );

  stage.tapCard(jokeId: 'opener', at: const CaptureTime(0));
  stage.tapCard(jokeId: 'van', at: const CaptureTime(60));
  stage.endSet(at: const CaptureTime(120));

  for (final segment in stage.segments) {
    expectThat(
      segment.provenance,
      SegmentProvenance.manual,
      'a boundary the comedian tapped is not one the app guessed',
    );
  }
});
