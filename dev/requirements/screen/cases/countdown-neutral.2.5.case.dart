import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 2.5 — With time in hand the countdown is bone-coloured.
final countdownNeutral_2_5 = RequirementCase('2.5', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.clocks,
    slug: 'countdown-neutral',
    id: '2.5',
  );
});
