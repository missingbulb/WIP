import 'package:flutter_test/flutter_test.dart';

/// The coded expectations a `logic` or `behavior` case asserts with.
///
/// Thin wrappers over `expect`, with the requirement's own words as the reason:
/// a red case should say which claim broke, not just which values differed.
void expectThat(Object? actual, Object? expected, String claim) {
  expect(actual, expected, reason: claim);
}

void expectTrue(bool actual, String claim) {
  expect(actual, isTrue, reason: claim);
}

void expectFalse(bool actual, String claim) {
  expect(actual, isFalse, reason: claim);
}

void expectAbsent(Object? actual, String claim) {
  expect(actual, isNull, reason: '$claim — unknown must stay absent, never a default');
}
