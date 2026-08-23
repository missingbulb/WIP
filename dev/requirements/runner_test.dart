import 'package:flutter_test/flutter_test.dart';
import 'package:setlist_ui/testing.dart';

import 'behavior/behavior_manifest.GENERATED.dart';
import 'logic/logic_manifest.GENERATED.dart';
import 'saga/saga_manifest.GENERATED.dart';
import 'screen/screen_manifest.GENERATED.dart';
import 'shared/requirement_case.dart';

/// The entry point every kind's cases run through.
///
/// A kind is not registered until it appears here, and the coverage gate checks
/// that too — a kind nothing runs is a kind that proves nothing.
void main() {
  // Once per file, never inside a test: reading the asset bundle works exactly
  // once per process, and a second call inside a test body hangs the next one.
  setUpAll(loadProductFonts);

  _run('logic', logicCases);
  _run('behavior', behaviorCases);
  _run('screen', screenCases);
  _run('saga', sagaCases);
}

void _run(String kind, List<RequirementCase> cases) {
  group(kind, () {
    for (final requirement in cases) {
      testWidgets(requirement.id, (tester) async => requirement.verify(tester));
    }
  });
}
