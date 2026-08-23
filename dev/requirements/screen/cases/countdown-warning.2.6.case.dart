import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 2.6 — Inside the last three minutes the countdown turns orange.
final countdownWarning_2_6 = RequirementCase('2.6', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(elapsed: const Duration(minutes: 18, seconds: 42)),
    region: StageRegion.clocks,
    slug: 'countdown-warning',
    id: '2.6',
  );
});
