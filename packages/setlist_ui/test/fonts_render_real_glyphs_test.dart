import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setlist_ui/testing.dart';

/// The assurance behind [loadProductFonts]: with the product's fonts loaded,
/// two strings that differ only in a character — not in length — must render
/// differently.
///
/// This is the test that keeps the gallery honest. Without it the harness can
/// regress to the stub font and every golden keeps passing while proving only
/// that the text is the right *length*; the spec pins exact copy at more than a
/// dozen leaves, and all of them would silently stop being checked. Watched it
/// fail with the fonts unloaded: the two renders below came back identical.
void main() {
  testWidgets('same-length copy changes are visible in a render', (tester) async {
    await loadProductFonts();

    final stand = await _render(tester, 'THE STAND');
    final stane = await _render(tester, 'THE STANE');

    // Same character count and the same style, so the layout box is identical:
    // a difference in the pixels can only be the glyphs themselves.
    expect(stand.width, stane.width);
    expect(stand.height, stane.height);
    expect(
      stand.pixels,
      isNot(equals(stane.pixels)),
      reason: 'THE STAND and THE STANE rendered identically — the renderer is '
          'drawing boxes, not glyphs, so no golden can see wrong copy',
    );
  });

}

final _boundary = GlobalKey();

class _Render {
  const _Render(this.width, this.height, this.pixels);
  final int width;
  final int height;
  final Uint8List pixels;
}

Future<_Render> _render(WidgetTester tester, String text) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          text,
          style: const TextStyle(fontFamily: 'DejaVuSans', fontSize: 32),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // toImage completes only outside the fake-async test zone.
  late _Render render;
  await tester.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    render = _Render(image.width, image.height, data!.buffer.asUint8List());
  });
  return render;
}
