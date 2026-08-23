import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 2.4 — Beside the countdown, elapsed and planned time read the set's position.
final elapsedAndPlanned_2_4 = RequirementCase('2.4', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.clocks,
    slug: 'elapsed-and-planned',
    id: '2.4',
  );
});
