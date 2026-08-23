import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 4.3 — A key names the three states, in order.
final stateKey_4_3 = RequirementCase('4.3', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.setListKey,
    slug: 'state-key',
    id: '4.3',
  );
});
