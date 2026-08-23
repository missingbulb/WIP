import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 4.4 — The list header counts jokes started out of jokes planned.
final startedTally_4_4 = RequirementCase('4.4', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.setListCount,
    slug: 'started-tally',
    id: '4.4',
  );
});
