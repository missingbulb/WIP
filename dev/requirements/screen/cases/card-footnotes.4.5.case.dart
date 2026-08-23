import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 4.5 — Each card's footnote states its state in time.
final cardFootnotes_4_5 = RequirementCase('4.5', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.grid,
    slug: 'card-footnotes',
    id: '4.5',
  );
});
