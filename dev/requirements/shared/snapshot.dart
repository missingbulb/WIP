import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setlist_ui/setlist_ui.dart';
import 'package:setlist_ui/testing.dart';

/// Renders the composed screen and compares one region of it with its golden.
///
/// The picture is always cropped out of a full render of the whole screen,
/// never laid out on its own: an element proved in isolation is proved in a
/// context the product never shows.
Future<void> expectRegion(
  WidgetTester tester,
  StageState state, {
  required StageRegion region,
  required String slug,
  required String id,
  String size = referenceSize,
}) async {
  await pumpStage(tester, state, size: size);
  await expectLater(
    find.byKey(region.key),
    matchesGoldenFile('screen/cases/$slug.$id.png'),
  );
}

/// Renders the whole screen and compares it with its golden.
///
/// For the three leaves whose claim *is* the screen. Everything else crops:
/// a reviewer approving a spec should be looking at the thing the line claims,
/// not re-reading a whole screen to find it.
Future<void> expectScreen(
  WidgetTester tester,
  StageState state, {
  required String slug,
  required String id,
  String? size,
}) async {
  await pumpStage(tester, state, size: size ?? referenceSize);
  await expectLater(
    find.byType(StageScreen),
    matchesGoldenFile(
      size == null
          ? 'screen/cases/$slug.$id.png'
          : 'screen/cases/$slug.$id.$size.png',
    ),
  );
}

/// The bounds a region ended up occupying, for a claim about placement rather
/// than appearance.
Rect regionBounds(WidgetTester tester, StageRegion region) =>
    tester.getRect(find.byKey(region.key));

/// The stage screen has no scrolling region, at any size.
///
/// A claim about the widget tree rather than the picture: a golden of a screen
/// that happens to fit says nothing about whether it would scroll with a longer
/// joke, and requirement 2.1 is about the screen, not this render of it.
void expectNoScrollable(WidgetTester tester) {
  expect(
    find.byType(Scrollable),
    findsNothing,
    reason: 'a comedian scrolling on stage has already lost the room',
  );
}
