import 'dart:math';

/// One performance of one joke: what the take-comparison screen compares.
class Take {
  Take({required this.jokeId, required this.showId, required this.peakLaughDuration});

  final String jokeId;
  final String showId;

  /// The longest laugh this take drew — the take's headline number.
  final Duration peakLaughDuration;
}

/// The anomaly rule behind the mockup's "2.4σ below the rest" flag.
abstract final class TakeAnomaly {
  /// How far below the rest a take must fall to be flagged.
  static const double sigmaThreshold = 2;

  /// Fewer comparison takes than this and there is no norm to deviate from.
  static const int minimumComparisonTakes = 3;

  /// How many standard deviations below the other takes' mean this take sits.
  ///
  /// Null when there are too few other takes, or when they are all identical
  /// and there is no spread to measure against — both are "unknown", and
  /// neither is a zero deviation.
  static double? deviation(Take take, {required List<Take> amongOthers}) {
    if (amongOthers.length < minimumComparisonTakes) return null;
    final values = [for (final t in amongOthers) t.peakLaughDuration.inMicroseconds / 1e6];
    final mean = values.reduce((a, b) => a + b) / values.length;
    var sumSquares = 0.0;
    for (final value in values) {
      sumSquares += (value - mean) * (value - mean);
    }
    // Sample standard deviation: these takes are the ones that happened, not
    // the population of every take the joke could ever draw.
    final sigma = sqrt(sumSquares / (values.length - 1));
    if (sigma <= 0) return null;
    return (mean - take.peakLaughDuration.inMicroseconds / 1e6) / sigma;
  }

  static bool isAnomalous(Take take, {required List<Take> amongOthers}) {
    final d = deviation(take, amongOthers: amongOthers);
    return d != null && d >= sigmaThreshold;
  }
}

/// The countdown's colour.
enum CountdownTone { neutral, warning, over }

abstract final class Countdown {
  /// Remaining time at which the countdown turns orange.
  static const Duration warningThreshold = Duration(minutes: 3);

  /// Remaining time; negative once the slot is over, because a comedian who is
  /// over needs to know by how much.
  static Duration remaining({required Duration plannedLength, required Duration elapsed}) =>
      plannedLength - elapsed;

  static CountdownTone tone(Duration remaining) {
    if (remaining <= Duration.zero) return CountdownTone.over;
    if (remaining <= warningThreshold) return CountdownTone.warning;
    return CountdownTone.neutral;
  }
}
