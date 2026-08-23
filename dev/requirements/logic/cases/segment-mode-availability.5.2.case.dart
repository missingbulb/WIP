import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 5.2 — The switch cannot be turned on while no autodetector is available,
/// and reports itself unavailable rather than silently ignoring the gesture.
final segmentModeAvailability_5_2 = RequirementCase('5.2', (tester) {
  final without = StageModel(jokes: const [], plannedLength: const Duration(minutes: 20));

  var refused = false;
  try {
    without.setSegmentMode(SegmentMode.autodetect);
  } on SegmentModeRefusal {
    refused = true;
  }

  expectTrue(refused, 'turning it on is refused, not ignored');
  expectThat(
    without.segmentMode,
    SegmentMode.manual,
    'and the mode does not half-change behind the refusal',
  );

  final available = StageModel(
    jokes: const [],
    plannedLength: const Duration(minutes: 20),
    autodetectAvailable: true,
  );
  available.setSegmentMode(SegmentMode.autodetect);
  expectThat(available.segmentMode, SegmentMode.autodetect, 'a registered detector makes it real');
});
