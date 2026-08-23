import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// One executable proof of one requirement leaf.
///
/// The id is the leaf it claims, and the coverage gate is what keeps that
/// honest: a case claiming an id no requirement carries, or a second case
/// claiming an id another already has, fails the build rather than passing
/// quietly.
class RequirementCase {
  const RequirementCase(this.id, this.verify);

  /// The dotted leaf id from `requirements.md`.
  final String id;

  /// Every kind takes the tester, whether or not it renders anything: it is
  /// what lets one runner execute all of them, and a rule that needs no
  /// renderer simply ignores it.
  final FutureOr<void> Function(WidgetTester tester) verify;
}
