import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 2.9 — The pacing bar carries one segment per joke in set order, sized by estimated
/// length, coloured told, live or queued.
final pacingBar_2_9 = RequirementCase('2.9', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.pacingBar,
    slug: 'pacing-bar',
    id: '2.9',
  );
});
