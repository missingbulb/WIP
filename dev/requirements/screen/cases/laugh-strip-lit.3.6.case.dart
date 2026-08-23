import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 3.6 — A laugh strip runs the width of the joke panel, lit green while the laugh
/// level is above the speak-over threshold.
final laughStripLit_3_6 = RequirementCase('3.6', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(laughLevel: 0.8),
    region: StageRegion.laughStrip,
    slug: 'laugh-strip-lit',
    id: '3.6',
  );
});
