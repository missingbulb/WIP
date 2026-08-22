/// Seconds since the capture session started, read off a monotonic source.
///
/// Card taps and laugh events are both stamped with one, so their interleaving
/// stays well defined across a wall-clock change (requirement 6.4).
class CaptureTime implements Comparable<CaptureTime> {
  const CaptureTime(this.seconds);

  final double seconds;

  @override
  int compareTo(CaptureTime other) => seconds.compareTo(other.seconds);

  @override
  bool operator ==(Object other) => other is CaptureTime && other.seconds == seconds;

  @override
  int get hashCode => seconds.hashCode;

  @override
  String toString() => 'CaptureTime($seconds)';
}

/// Anything the timeline can order.
abstract class CaptureTimed {
  CaptureTime get at;
}

/// A span of room noise loud enough to count as a laugh.
///
/// Start, duration and intensity, and nothing else (requirement 6.3): the
/// detector is a loudness threshold, so it has no class to report and no
/// confidence to report, and a field nothing can honestly fill is worse than an
/// absent one.
class LaughEvent implements CaptureTimed {
  const LaughEvent({required this.at, required this.duration, required this.intensity});

  @override
  final CaptureTime at;
  final double duration;

  /// Loudness of the span, 0..1.
  final double intensity;
}

/// A card tap, stamped on the capture clock.
class TapEvent implements CaptureTimed {
  const TapEvent({required this.at, required this.jokeId});

  @override
  final CaptureTime at;
  final String jokeId;
}

/// Taps and laugh events merged onto the one clock they share.
///
/// Equal stamps keep taps first: a tap is the boundary the laughs after it
/// belong to, so ordering them the other way would file a bit's first laugh
/// under the bit before it.
List<CaptureTimed> timeline({
  required List<TapEvent> taps,
  required List<LaughEvent> laughs,
}) {
  final entries = <CaptureTimed>[...taps, ...laughs];
  // Sorted by index as the final tie-break so the result is a pure function of
  // the input order — a stable answer is what makes a golden of it reviewable.
  final indexed = entries.indexed.toList();
  indexed.sort((a, b) {
    final byTime = a.$2.at.compareTo(b.$2.at);
    if (byTime != 0) return byTime;
    final aTap = a.$2 is TapEvent;
    if (aTap != (b.$2 is TapEvent)) return aTap ? -1 : 1;
    return a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}
