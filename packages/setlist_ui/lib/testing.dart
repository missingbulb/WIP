import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'setlist_ui.dart';

export 'src/font_assurance.dart' show expectFontsRenderRealGlyphs;

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

  if (manifest.isEmpty) {
    throw StateError(
      'FontManifest.json declares no families, so every render would use the '
      'glyph-less fallback and any golden of it would be blind to copy.',
    );
  }

  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(_bareFamily(entry['family'] as String));
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// The family name a widget asks for, from the name the manifest lists it under.
///
/// A package's own fonts appear in its manifest unprefixed, but the same fonts
/// seen from a package that *depends* on it are namespaced
/// `packages/<package>/<family>`. A `TextStyle` names the bare family either
/// way, so registering the manifest's name verbatim loads the bytes under a
/// name nothing asks for: the text then renders in the glyph-less fallback, and
/// a golden of it is blind to copy while still passing.
String _bareFamily(String manifestFamily) {
  final match = RegExp(r'^packages/[^/]+/(.+)$').firstMatch(manifestFamily);
  return match?.group(1) ?? manifestFamily;
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

/// The composed screen, as one capturable layer.
///
/// Every picture in the spec — whole screen or one element — is read out of
/// this, so an element is always proved in the context the product shows it in.
final stageRootKey = GlobalKey(debugLabel: 'stage-root');

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
            // The boundary every picture in the spec is read out of: capturing
            // an element needs a layer, and the composed screen is the only one
            // the product actually draws.
            child: RepaintBoundary(
              key: stageRootKey,
              child: StageScreen(state: state),
            ),
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
