import 'dart:math';

/// A random identifier for a newly created joke, set, show or segment.
///
/// A v4 UUID in the canonical form, built from the platform's secure random
/// source. Written out rather than taken from a package: it is the only thing
/// the product needs from one, and an id generator is a few lines.
///
/// Nothing reads meaning out of an id, so any two ids only ever need to differ.
String newId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
      '-${hex.substring(16, 20)}-${hex.substring(20)}';
}
