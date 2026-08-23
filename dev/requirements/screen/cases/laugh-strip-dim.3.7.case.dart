import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 3.7 — Below the threshold the same strip is dim.
final laughStripDim_3_7 = RequirementCase('3.7', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.laughStrip,
    slug: 'laugh-strip-dim',
    id: '3.7',
  );
});
