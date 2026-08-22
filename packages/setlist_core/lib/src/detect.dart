import 'dart:math';
import 'dart:typed_data';

import 'capture.dart';

/// The two numbers laugh detection turns on, and the frame it measures over.
///
/// Held in one named object rather than spread as defaults across the detector:
/// they are a calibration the owner approves against real recordings, and a
/// calibration nobody can point at is one nobody can review. [approved] is the
/// value the product ships; a caller wanting different numbers has to say so.
class DetectionSettings {
  const DetectionSettings({
    required this.frame,
    required this.minimumDuration,
    required this.thresholdOverBaseline,
    required this.baselinePercentile,
  });

  /// The window short-term loudness is measured over. Long enough to average
  /// out a single syllable, short enough to place a laugh's edge.
  final Duration frame;

  /// How long the room has to stay loud before it counts as a laugh. Below
  /// this, it is a shout, a dropped glass, or a word landing hard.
  final Duration minimumDuration;

  /// How far above the room's own baseline counts as loud, as a ratio of
  /// amplitude. A ratio rather than an absolute level, because it is the room
  /// getting louder *than itself* that marks a laugh — a quiet room and a loud
  /// one both have one.
  final double thresholdOverBaseline;

  /// Which quantile of the recording's frames stands for "the room, not
  /// reacting". Not the minimum, which is whatever the quietest single frame
  /// happened to be, and not the mean, which the laughter itself drags up.
  final double baselinePercentile;

  /// The calibration the product ships.
  ///
  /// Provisional: these numbers have never been checked against a real club
  /// recording, only against synthesised signals. Risk R1 in the architecture
  /// is exactly this, and it is a Phase B step to close.
  static const DetectionSettings approved = DetectionSettings(
    frame: Duration(milliseconds: 50),
    minimumDuration: Duration(milliseconds: 600),
    thresholdOverBaseline: 2.5,
    baselinePercentile: 0.2,
  );
}

/// Turns a finished recording into the laugh events it contains.
///
/// A pure function of the samples: no clock, no randomness, no I/O, and no
/// model — so the same recording yields the same events on every platform and
/// every run (requirement 6.9), and a take's numbers stay comparable with one
/// recorded a year earlier.
///
/// What it is doing is deliberately crude (decision D7): in a club, sustained
/// room noise above the room's own level is laughter, and the product does not
/// need to tell laughter from applause from cheering. It will also fire on a
/// dropped tray. Phase A ships manual segmentation regardless, so a false event
/// costs a mark on a timeline and never a lost bit.
///
/// [samples] are mono, in -1..1. [sampleRate] is in hertz.
List<LaughEvent> detectLaughs(
  Float64List samples, {
  required int sampleRate,
  DetectionSettings settings = DetectionSettings.approved,
}) {
  if (sampleRate <= 0 || samples.isEmpty) return const [];

  final frameLength = (sampleRate * settings.frame.inMicroseconds / 1e6).round();
  if (frameLength <= 0) return const [];

  final levels = _frameLevels(samples, frameLength);
  if (levels.isEmpty) return const [];

  final baseline = _percentile(levels, settings.baselinePercentile);
  // A silent room has a zero baseline, and everything is infinitely above
  // nothing. There is no laughter in silence, so there is nothing to report.
  if (baseline <= 0) return const [];
  final threshold = baseline * settings.thresholdOverBaseline;

  final frameSeconds = frameLength / sampleRate;
  final minimumFrames = (settings.minimumDuration.inMicroseconds / 1e6 / frameSeconds).ceil();

  final events = <LaughEvent>[];
  var runStart = -1;

  void closeRun(int endExclusive) {
    if (runStart < 0) return;
    final frames = endExclusive - runStart;
    if (frames >= minimumFrames) {
      var peak = 0.0;
      for (var i = runStart; i < endExclusive; i++) {
        peak = max(peak, levels[i]);
      }
      events.add(LaughEvent(
        at: CaptureTime(runStart * frameSeconds),
        duration: frames * frameSeconds,
        // Absolute, not relative to the loudest moment of this recording: an
        // intensity that means "loud for this show" could not be compared with
        // another show, which is the whole point of keeping takes.
        intensity: peak.clamp(0.0, 1.0),
      ));
    }
    runStart = -1;
  }

  for (var i = 0; i < levels.length; i++) {
    if (levels[i] >= threshold) {
      if (runStart < 0) runStart = i;
    } else {
      closeRun(i);
    }
  }
  // A laugh still going when the recording stops is a laugh that happened.
  closeRun(levels.length);

  return events;
}

/// Root-mean-square amplitude per whole frame. A trailing partial frame is
/// dropped: its level would be measured over a shorter window than every other,
/// and so would not be comparable with them.
List<double> _frameLevels(Float64List samples, int frameLength) {
  final frames = samples.length ~/ frameLength;
  final levels = <double>[];
  for (var f = 0; f < frames; f++) {
    var sumSquares = 0.0;
    final start = f * frameLength;
    for (var i = start; i < start + frameLength; i++) {
      sumSquares += samples[i] * samples[i];
    }
    levels.add(sqrt(sumSquares / frameLength));
  }
  return levels;
}

/// The value at [fraction] through the sorted levels, by nearest rank.
double _percentile(List<double> levels, double fraction) {
  final sorted = [...levels]..sort();
  final index = (fraction * (sorted.length - 1)).round().clamp(0, sorted.length - 1);
  return sorted[index];
}
