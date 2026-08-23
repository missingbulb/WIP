import 'package:setlist_ui/setlist_ui.dart';
import 'package:setlist_ui/testing.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 3.1 — The joke being performed occupies the top region, its body text the largest
/// text on the screen.
// whole-screen: "the largest text on the screen" compares the panel against everything else, so a crop of the panel cannot prove it.
final currentJoke_3_1 = RequirementCase('3.1', (tester) async {
  await expectScreen(tester, StageFixture.state(), slug: 'current-joke', id: '3.1');
});
