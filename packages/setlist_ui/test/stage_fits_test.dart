import 'package:flutter_test/flutter_test.dart';
import 'package:setlist_ui/setlist_ui.dart';
import 'package:setlist_ui/testing.dart';

/// The stage screen fits every supported size, with one test per size.
///
/// This lives beside the widgets rather than in the requirements suite because
/// of how it has to run: each size needs a test of its own. Rendering several
/// sizes in one test updates the previous tree instead of replacing it, and
/// render objects on their way out get laid out against the new width — which
/// reports an overflow for a screen that is no longer on the way in. Requirement
/// 2.1's case owns the pictures; this owns the fit.
void main() {
  setUpAll(loadProductFonts);

  for (final size in stageSizes.keys) {
    testWidgets('the stage screen fits $size', (tester) async {
      await pumpStage(tester, StageFixture.state(), size: size);

      expect(
        tester.takeException(),
        isNull,
        reason: 'nothing on the stage screen may overflow at $size',
      );
    });

    testWidgets('the stage screen fits $size before the first tap', (tester) async {
      // The emptier state is not automatically the safer one: it drops the
      // joke body and the tags, which changes what the set list is left with.
      await pumpStage(tester, StageFixture.beforeTheFirstTap(), size: size);

      expect(tester.takeException(), isNull, reason: 'the queued set fits $size too');
    });
  }
}
