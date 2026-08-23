import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 2.3 — The header names the room, upper-cased and letter-spaced.
final venueLine_2_3 = RequirementCase('2.3', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.venue,
    slug: 'venue-line',
    id: '2.3',
  );
});
