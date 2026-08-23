import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 4.7 — A joke re-opened after being told still counts once in the started
/// tally.
final startedCount_4_7 = RequirementCase('4.7', (tester) {
  final stage = StageModel(
    jokes: [
      Joke(id: 'opener', title: 'Opener', body: ''),
      Joke(id: 'van', title: 'Van', body: ''),
      Joke(id: 'closer', title: 'Closer', body: ''),
    ],
    plannedLength: const Duration(minutes: 20),
  );

  expectThat(stage.startedCount, 0, 'nothing is started before anything is tapped');

  stage.tapCard(jokeId: 'van', at: const CaptureTime(0));
  stage.tapCard(jokeId: 'opener', at: const CaptureTime(60));
  stage.tapCard(jokeId: 'van', at: const CaptureTime(200));

  expectThat(stage.segments.length, 3, 'the van has two segments');
  expectThat(stage.startedCount, 2, 'but counts once in the tally');
  expectThat(stage.plannedCount, 3, 'out of the jokes planned');
});
