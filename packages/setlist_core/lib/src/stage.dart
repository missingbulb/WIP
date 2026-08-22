import 'capture.dart';
import 'material.dart';

/// How bit boundaries are decided during a set.
enum SegmentMode {
  /// The comedian taps cards to mark boundaries.
  manual,

  /// Boundaries are inferred from the audio.
  autodetect,
}

/// Why turning the segment-mode switch on did not take.
///
/// A refusal rather than a silently ignored gesture: the switch is read on
/// stage, and a control that shows "on" while nothing detects would lie in the
/// one place a lie costs a set.
class SegmentModeRefusal implements Exception {
  const SegmentModeRefusal.autodetectUnavailable();

  @override
  String toString() => 'SegmentModeRefusal: no autodetector is registered';
}

/// A joke's state in the set list.
enum CardState { queued, live, told }

/// One card in the 3-column grid.
///
/// Deliberately carries no laugh data: requirement 4.6 keeps scores off the
/// stage screen, and a field that does not exist cannot leak into a layout
/// later.
class StageCard {
  StageCard({required this.joke, this.state = CardState.queued, this.runTime = Duration.zero});

  final Joke joke;
  CardState state;

  /// How long this joke has run so far, across its closed segments.
  Duration runTime;

  String get id => joke.id;
}

/// What a card tap did.
sealed class TapOutcome {
  const TapOutcome();
}

/// The tapped joke is now live; the previous one's segment closed.
class TapSwitched extends TapOutcome {
  const TapSwitched(this.jokeId);
  final String jokeId;

  @override
  bool operator ==(Object other) => other is TapSwitched && other.jokeId == jokeId;

  @override
  int get hashCode => jokeId.hashCode;
}

/// The tapped joke was already live. Nothing changed.
class TapIgnored extends TapOutcome {
  const TapIgnored();

  @override
  bool operator ==(Object other) => other is TapIgnored;

  @override
  int get hashCode => 0;
}

/// The live screen's state machine: the set list, which joke is running, and
/// the segments the taps produce.
class StageModel {
  StageModel({
    required List<Joke> jokes,
    required this.plannedLength,
    this.autodetectAvailable = false,
  }) : cards = [for (final joke in jokes) StageCard(joke: joke)];

  /// Takes resolved jokes rather than a set: what goes on stage is the
  /// material, and resolving a set's ids is the library's job.
  final List<StageCard> cards;
  final List<Segment> segments = [];

  /// Registered when a detector exists; false through Phase A.
  final bool autodetectAvailable;

  /// The slot.
  final Duration plannedLength;

  SegmentMode _segmentMode = SegmentMode.manual;
  SegmentMode get segmentMode => _segmentMode;

  String? get liveJokeId {
    for (final card in cards) {
      if (card.state == CardState.live) return card.id;
    }
    return null;
  }

  /// Jokes started out of jokes planned — the set-list header's count.
  ///
  /// A joke re-opened after being told still counts once (requirement 4.7),
  /// which is why this counts distinct jokes rather than segments.
  int get startedCount => {for (final segment in segments) segment.jokeId}.length;

  int get plannedCount => cards.length;

  /// How long a joke has run by [now], across every segment it has: the closed
  /// ones plus the one still open.
  ///
  /// A card's own [StageCard.runTime] counts only closed segments, so the live
  /// joke needs the clock to answer.
  Duration runTimeOf(String jokeId, {required CaptureTime at}) {
    var seconds = 0.0;
    for (final segment in segments) {
      if (segment.jokeId != jokeId) continue;
      seconds += (segment.end ?? at).seconds - segment.start.seconds;
    }
    return Duration(microseconds: (seconds * 1e6).round());
  }

  /// Tapping a card marks the start of that joke.
  TapOutcome tapCard({required String jokeId, required CaptureTime at}) {
    final index = cards.indexWhere((card) => card.id == jokeId);
    if (index < 0) return const TapIgnored();
    if (cards[index].state == CardState.live) return const TapIgnored();

    _closeOpenSegment(at);
    segments.add(Segment(jokeId: jokeId, start: at, provenance: SegmentProvenance.manual));
    cards[index].state = CardState.live;
    return TapSwitched(jokeId);
  }

  /// Ends the set: the joke still running gets its closing boundary.
  void endSet({required CaptureTime at}) => _closeOpenSegment(at);

  /// The segment-mode switch.
  ///
  /// Throws rather than staying silently off, so the switch never claims a
  /// capability the app does not have (requirement 5.2).
  void setSegmentMode(SegmentMode mode) {
    if (mode == SegmentMode.autodetect && !autodetectAvailable) {
      throw const SegmentModeRefusal.autodetectUnavailable();
    }
    _segmentMode = mode;
  }

  void _closeOpenSegment(CaptureTime at) {
    final openIndex = segments.lastIndexWhere((segment) => segment.end == null);
    if (openIndex < 0) return;
    final closed = segments[openIndex]..end = at;
    final cardIndex = cards.indexWhere((card) => card.id == closed.jokeId);
    if (cardIndex < 0) return;
    cards[cardIndex].state = CardState.told;
    cards[cardIndex].runTime += closed.duration ?? Duration.zero;
  }
}
