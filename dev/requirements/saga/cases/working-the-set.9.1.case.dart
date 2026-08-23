import 'package:setlist_core/setlist_core.dart';
import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/saga.dart';

/// 9.1 — A whole set, in the moments a single frame cannot hold: the opener
/// going up, the set moving on, the callback taking the comedian back to a bit
/// they have already told, and the slot running out underneath them.
final workingTheSet_9_1 = sagaCase(
  id: '9.1',
  slug: 'working-the-set',
  from: () => StageModel(
    jokes: StageFixture.jokes,
    plannedLength: StageFixture.slot,
  ),
  steps: [
    SagaStep(
      'the set is queued and the recording is running; nothing has started yet',
      region: StageRegion.grid,
      act: (model, elapsed) => Duration.zero,
    ),
    SagaStep(
      'the opener goes up — its card turns live and the joke takes the top of the screen',
      // No region: this step changes the panel and the grid together, which is
      // the whole point of it.
      act: (model, elapsed) {
        model.tapCard(jokeId: 'crowd-work', at: const CaptureTime(0));
        return const Duration(seconds: 40);
      },
    ),
    SagaStep(
      'three bits in, the set is moving: the told cards go green behind the live one',
      region: StageRegion.grid,
      act: (model, elapsed) {
        model.tapCard(jokeId: 'dads-van', at: const CaptureTime(190));
        model.tapCard(jokeId: 'flatmate-rota', at: const CaptureTime(315));
        model.tapCard(jokeId: 'airport-security', at: const CaptureTime(423));
        return const Duration(minutes: 8, seconds: 27);
      },
    ),
    SagaStep(
      'the callback lands, so the comedian goes back to the van — it counts once, not twice',
      region: StageRegion.grid,
      act: (model, elapsed) {
        model.tapCard(jokeId: 'dads-van', at: const CaptureTime(640));
        return const Duration(minutes: 11, seconds: 40);
      },
    ),
    SagaStep(
      'into the closer with 1:18 left, and the countdown has gone orange',
      region: StageRegion.clocks,
      act: (model, elapsed) {
        model.tapCard(jokeId: 'closer-ferry', at: const CaptureTime(1050));
        return const Duration(minutes: 18, seconds: 42);
      },
    ),
    SagaStep(
      'a minute over: the countdown is red and counting up',
      region: StageRegion.clocks,
      act: (model, elapsed) => const Duration(minutes: 21),
    ),
  ],
);
