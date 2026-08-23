import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 3.2 — The current joke's title sits above its body, with the time it has been
/// running so far.
final jokeRunTime_3_2 = RequirementCase('3.2', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.jokeTitleRow,
    slug: 'joke-run-time',
    id: '3.2',
  );
});
