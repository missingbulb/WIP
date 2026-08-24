// The Dart half of the drift guard the two laugh detectors share.
//
// The vectors are generated from this implementation, so this suite is not
// asking whether the detector is right — it is asking whether the committed
// vectors still describe it. A change made here and not regenerated (and so not
// ported to the pipeline) is red before it can split the numbers a take is
// compared on. `dev/conformance/README.md` owns the landing procedure.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:setlist_core/setlist_core.dart';
import 'package:test/test.dart';

void main() {
  final vectors = jsonDecode(
    File('../../dev/conformance/detector-conformance.GENERATED.json').readAsStringSync(),
  ) as Map<String, Object?>;

  test('the vectors were generated from the calibration the product ships', () {
    expect(vectors['settings'], {
      'frameMilliseconds': DetectionSettings.approved.frame.inMilliseconds,
      'minimumDurationMilliseconds':
          DetectionSettings.approved.minimumDuration.inMilliseconds,
      'thresholdOverBaseline': DetectionSettings.approved.thresholdOverBaseline,
      'baselinePercentile': DetectionSettings.approved.baselinePercentile,
    });
  });

  for (final entry in (vectors['cases'] as List).cast<Map<String, Object?>>()) {
    test('${entry['name']} — ${entry['what']}', () {
      final bytes = base64.decode(entry['samples'] as String);
      final samples = Float64List.view(
        bytes.buffer,
        bytes.offsetInBytes,
        bytes.lengthInBytes ~/ 8,
      );

      final events = detectLaughs(samples, sampleRate: entry['sampleRate'] as int);
      final expected = (entry['events'] as List).cast<Map<String, Object?>>();

      expect(events, hasLength(expected.length));
      for (var i = 0; i < events.length; i++) {
        expect(events[i].at.seconds, expected[i]['at']);
        expect(events[i].duration, expected[i]['duration']);
        expect(events[i].intensity, expected[i]['intensity']);
      }
    });
  }
}
