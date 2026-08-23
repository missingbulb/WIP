import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 3.3 — Crucial setups render highlighted inside the body: orange and bold, against
/// the body's bone.
final setupHighlight_3_3 = RequirementCase('3.3', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.jokeBody,
    slug: 'setup-highlight',
    id: '3.3',
  );
});
