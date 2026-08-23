import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 4.1 — The set list renders as a grid of cards, each carrying its joke's title,
/// filling the height the joke panel leaves.
final setListGrid_4_1 = RequirementCase('4.1', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.grid,
    slug: 'set-list-grid',
    id: '4.1',
  );
});
