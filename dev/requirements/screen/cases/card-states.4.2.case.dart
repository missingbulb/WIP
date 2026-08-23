import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 4.2 — Told, live and queued cards are each coloured differently.
final cardStates_4_2 = RequirementCase('4.2', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.grid,
    slug: 'card-states',
    id: '4.2',
  );
});
