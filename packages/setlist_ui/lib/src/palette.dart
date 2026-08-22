import 'package:flutter/painting.dart';

/// The stage palette from the mockups: dark enough for a club, warm enough not
/// to read as a terminal.
///
/// Told is green, live is orange, over-time is red — the three states a
/// comedian reads at a glance from behind a mic.
abstract final class Palette {
  static const ink = Color(0xFF100E0B);
  static const panel = Color(0xFF1C1813);
  static const rule = Color(0xFF26221C);
  static const edge = Color(0xFF3A3733);
  static const mute = Color(0xFF6E685F);
  static const dim = Color(0xFF8A8378);
  static const bone = Color(0xFFE8E3DA);
  static const green = Color(0xFF00D9A3);
  static const greenDeep = Color(0xFF003D2E);
  static const greenInk = Color(0xFF00A87E);
  static const orange = Color(0xFFFF9500);
  static const orangeDeep = Color(0xFF6B3D00);
  static const red = Color(0xFFFF3B30);
}

/// The families the product draws with.
///
/// Named rather than left to the platform: the SwiftUI original asked for the
/// *system* font, which differs between iOS and Android and does not exist at
/// all in the test renderer. A golden is only an approval record if every
/// machine draws the same glyphs, so the families are bundled and named here
/// (risk R6).
abstract final class Typeface {
  static const sans = 'DejaVuSans';

  /// For anything that counts. A proportional digit changing width shifts the
  /// digits beside it, and a clock that jitters cannot be read at a glance.
  static const mono = 'DejaVuSansMono';
}
