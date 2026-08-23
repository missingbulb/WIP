import 'package:setlist_ui/setlist_ui.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 2.2 — A red dot sits at the head of the header whenever capture is running.
final recordingIndicator_2_2 = RequirementCase('2.2', (tester) async {
  await expectRegion(
    tester,
    StageFixture.state(),
    region: StageRegion.venue,
    slug: 'recording-indicator',
    id: '2.2',
  );
});
