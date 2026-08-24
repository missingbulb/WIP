import 'package:flutter_test/flutter_test.dart';
import 'package:setlist_ui/testing.dart';

/// The assurance behind [loadProductFonts], run in the package that declares
/// the fonts. Its twin in `dev/requirements` runs the same check in the package
/// that renders the spec's goldens — font resolution is per-package, so passing
/// here says nothing about passing there.
void main() {
  setUpAll(loadProductFonts);

  testWidgets('same-length copy changes are visible in a render', (tester) async {
    await expectFontsRenderRealGlyphs(tester);
  });
}
