import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
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
    await _cropOfScreen(tester, regionBounds(tester, region)),
    matchesGoldenFile('screen/cases/$slug.$id.png'),
  );
}

/// The composed screen, with everything outside [rect] cut away.
///
/// Cropping here rather than pointing the matcher at the element itself:
/// `matchesGoldenFile` given a `Finder` captures that finder's nearest
/// *ancestor* `RepaintBoundary`, not the widget's own bounds. The screen has no
/// boundary per element, so every such capture silently returned the whole
/// screen — leaving seventeen leaves about seventeen different elements all
/// proved by one identical picture.
Future<ui.Image> _cropOfScreen(WidgetTester tester, Rect rect) async {
  final boundary =
      stageRootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  // Real image work never completes inside the fake-async test zone.
  late ui.Image cropped;
  await tester.runAsync(() async {
    final whole = await boundary.toImage();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      whole,
      rect,
      Offset.zero & rect.size,
      Paint(),
    );
    cropped = await recorder
        .endRecording()
        .toImage(rect.width.round(), rect.height.round());
    whole.dispose();
  });
  return cropped;
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
