import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 2.7 — Once the slot is over the countdown turns red and counts up.
final countdownOver_2_7 = RequirementCase('2.7', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(elapsed: const Duration(minutes: 21)),
    region: StageRegion.clocks,
    slug: 'countdown-over',
    id: '2.7',
  );
});
