import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:setlist_core/setlist_core.dart';
import 'package:setlist_ui/setlist_ui.dart';
import 'package:setlist_ui/testing.dart';

import 'requirement_case.dart';

/// One beat of a story: what happens, the caption that narrates it, and the
/// part of the screen it changes.
///
/// The caption is written in user terms, because it is what surfaces in the
/// spec's gallery beneath the frame it labels. The region is what the frame is
/// cropped to: a storyboard of six whole screens costs a reader the section and
/// shows them mostly what did not move. A step that genuinely changes the whole
/// screen leaves it null and says so by doing.
class SagaStep {
  const SagaStep(this.caption, {this.region, required this.act});

  final String caption;
  final StageRegion? region;

  /// Drives the model forward and answers where the set clock now stands.
  final Duration Function(StageModel model, Duration elapsed) act;
}

/// A saga proves what a single frame cannot: what arriving, tapping or time
/// passing *changes*.
///
/// Each step drives the same real screen every other kind renders, and one
/// frame is captured after each — never a slideshow of hand-arranged states.
RequirementCase sagaCase({
  required String id,
  required String slug,
  required StageModel Function() from,
  required List<SagaStep> steps,
}) {
  return RequirementCase(id, (tester) async {
    final model = from();
    var elapsed = Duration.zero;
    final captions = <String>[];

    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      elapsed = step.act(model, elapsed);
      final state = StageState(
        model: model,
        venue: StageFixture.venue,
        elapsed: elapsed,
      );

      await pumpStage(tester, state);
      final frame = (index + 1).toString().padLeft(2, '0');
      await expectLater(
        step.region == null
            ? find.byType(StageScreen)
            : find.byKey(step.region!.key),
        matchesGoldenFile('saga/cases/$slug.$id.step-$frame.png'),
      );
      captions.add(step.caption);
    }

    // Generated beside the frames rather than hand-maintained in Markdown: a
    // caption list written by hand drifts from the frames it labels, and the
    // gate fails when their counts disagree.
    File('saga/cases/$slug.$id.captions.json')
        .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(captions)}\n');
  });
}
