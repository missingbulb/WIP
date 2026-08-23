import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 5.1 — The segment-mode control is a switch, labelled for the mode it selects.
final segmentModeSwitch_5_1 = RequirementCase('5.1', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.segmentMode,
    slug: 'segment-mode-switch',
    id: '5.1',
  );
});
