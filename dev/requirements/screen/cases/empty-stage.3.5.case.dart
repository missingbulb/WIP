import 'package:setlist_ui/setlist_ui.dart';
import 'package:setlist_ui/testing.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 3.5 — Before the first card is tapped the region invites one and no card is live.
// whole-screen: the leaf claims what the joke region says and that no card is live, so the picture has to hold both.
final emptyStage_3_5 = RequirementCase('3.5', (tester) async {
  await expectScreen(tester, StageFixture.beforeTheFirstTap(), slug: 'empty-stage', id: '3.5');
});
