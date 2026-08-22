import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
