import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'setlist_ui.dart';

/// Loads the families the product bundles into the test renderer.
///
/// A test environment renders text in a glyph-less stub font by default, where
/// every character is the same filled box — so two different strings of equal
/// length are pixel-identical and a golden accepts either. Measured on this
/// toolchain: `THE STAND` and `THE STANE` produced byte-identical renders,
/// while a length change produced a 17976px diff. Every requirement that pins
/// exact copy is therefore unprovable until this has run.
///
/// The families are read from the bundle's own `FontManifest.json`, so what the
/// harness renders with is whatever the product ships — the two cannot drift
/// apart by editing one of them.
/// Call this from `setUpAll`, never from inside a test.
///
/// Reading the bundle from within a `testWidgets` body works exactly once per
/// process: the second call never completes, and it presents as the second test
/// in the file hanging until its ten-minute timeout rather than as an error.
/// `setUpAll` runs outside the per-test zones, so one call there serves every
/// test in the file.
Future<void> loadProductFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;

  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// The sizes the product is specified at.
///
/// Only a leaf whose claim *is* the screen renders once per size; every other
/// leaf is proved by a crop at [referenceSize] (decision D11).
const stageSizes = <String, Size>{
  'tablet-portrait': Size(834, 1112),
  'tablet-landscape': Size(1112, 834),
  'phone-portrait': Size(390, 844),
  'phone-landscape': Size(844, 390),
};

const referenceSize = 'tablet-portrait';

/// The sizes in the order a single test should render them: widest last.
///
/// Rendering from narrow to wide is not cosmetic. Flutter updates the previous
/// tree rather than rebuilding it, so shrinking the box lays the outgoing
/// render objects out against a width they were never built for, and they
/// report overflows for a screen nobody is looking at any more. Growing never
/// does that.
List<String> get stageSizesWidestLast {
  final names = stageSizes.keys.toList();
  names.sort((a, b) => stageSizes[a]!.width.compareTo(stageSizes[b]!.width));
  return names;
}

/// Renders the real stage screen at one of the specified sizes.
///
/// Expects [loadProductFonts] to have run in the file's `setUpAll`.
///
/// Every screen case goes through here, so a golden differs from its
/// neighbours only where the requirement under test differs. The device pixel
/// ratio is pinned to 1 so a golden's pixel dimensions are its logical ones and
/// a reader can measure the picture against the spec.
Future<void> pumpStage(
  WidgetTester tester,
  StageState state, {
  String size = referenceSize,
}) async {
  final bounds = stageSizes[size]!;
  // The surface has to be at least as large as what is drawn on it: a box
  // taller than the viewport lays out against unbounded height, and every
  // Expanded inside it silently stops working.
  tester.view
    ..physicalSize = bounds
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // One test may render several sizes in turn. The old tree is unmounted in a
  // frame of its own first: updating straight from one size to the next lays
  // out render objects that are on their way out against the new width, and
  // they report overflows from a screen nobody is looking at any more.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await tester.pumpWidget(
    // The whole subtree is keyed by size, not just the screen inside it: when
    // one test renders several sizes in turn, Flutter otherwise updates the
    // previous tree in place, and render objects that are on their way out get
    // laid out once more against the new width.
    KeyedSubtree(
      key: ValueKey(size),
      child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: bounds),
        child: Center(
          child: SizedBox(
            width: bounds.width,
            height: bounds.height,
            // Keyed by size so a second render in the same test builds a fresh
            // tree rather than updating the last one: reused elements keep
            // their old slots, and a card ends up laid out against a width the
            // screen no longer has.
            child: StageScreen(state: state),
          ),
        ),
      ),
    ),
    ),
  );
  // Fixed pumps, never pumpAndSettle: the switch keeps tickers running, so
  // "settled" never arrives and the wait burns pumpAndSettle's ten-minute
  // timeout. A fixed pump also makes an in-flight state a capturable frame
  // rather than something that has to be waited out.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
