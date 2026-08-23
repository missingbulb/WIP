import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 3.4 — The joke's optional text renders under the body as bordered tags.
final jokeOptionalText_3_4 = RequirementCase('3.4', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.jokeTags,
    slug: 'joke-optional-text',
    id: '3.4',
  );
});
