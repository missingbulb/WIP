import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setlist_ui/setlist_ui.dart';
import 'package:setlist_ui/testing.dart';

void main() {
  setUpAll(loadProductFonts);

  group('2.1 the stage screen fits one screen with no scrolling region', () {
    // The whole-screen leaf, and the only one rendered per size class.
    for (final size in stageSizes.keys) {
      testWidgets('at $size', (tester) async {
        await pumpStage(tester, StageFixture.state(), size: size);

        await expectLater(
          find.byType(StageScreen),
          matchesGoldenFile('goldens/one-screen.2.1.$size.png'),
        );
      });
    }

    testWidgets('nothing on it scrolls', (tester) async {
      await pumpStage(tester, StageFixture.state());

      // Asserted against the widget tree rather than the picture: a golden of a
      // screen that happens to fit says nothing about whether it would scroll
      // with a longer joke.
      expect(find.byType(Scrollable), findsNothing);
    });
  });

  testWidgets('3.1 the current joke takes the top region', (tester) async {
    await pumpStage(tester, StageFixture.state());

    await expectLater(
      find.byType(StageScreen),
      matchesGoldenFile('goldens/current-joke.3.1.png'),
    );
  });

  testWidgets('3.5 before the first tap the region invites one', (tester) async {
    await pumpStage(tester, StageFixture.beforeTheFirstTap());

    await expectLater(
      find.byType(StageScreen),
      matchesGoldenFile('goldens/empty-stage.3.5.png'),
    );
  });
}
