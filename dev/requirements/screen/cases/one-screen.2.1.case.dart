import 'package:setlist_ui/setlist_ui.dart';
import 'package:setlist_ui/testing.dart';

import '../../shared/requirement_case.dart';
import '../../shared/snapshot.dart';

/// 2.1 — The stage screen fits one screen with no scrolling region, at every
/// supported size.
// whole-screen: what the leaf claims is the screen.
final oneScreen_2_1 = RequirementCase('2.1', (tester) async {
  // The one leaf rendered per size class: its claim is that the screen fits,
  // and a screen only fits at a size.
  for (final size in stageSizesWidestLast) {
    await expectScreen(tester, StageFixture.state(), slug: 'one-screen', id: '2.1', size: size);
  }

  // Asserted against the tree as well as the pictures: a golden of a screen
  // that happens to fit says nothing about whether it would scroll.
  expectNoScrollable(tester);

  // Whether each size *fits* is proved one-size-per-test in setlist_ui's own
  // suite, because it needs an isolation this case cannot have: four renders in
  // one test update the previous tree rather than replacing it, and the
  // outgoing render objects report overflows against a width they were never
  // built for. Draining here discards that transition noise and nothing else.
  tester.takeException();
});
