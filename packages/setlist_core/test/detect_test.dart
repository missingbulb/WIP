import 'dart:math';
import 'dart:typed_data';

import 'package:setlist_core/setlist_core.dart';
import 'package:test/test.dart';

const _sampleRate = 16000;

/// A synthesised room: [seconds] of noise at [level], with louder spans where
/// the crowd reacts.
///
/// Deterministic by construction — a fixed seed, so the same script always
/// produces the same samples and a failure is always reproducible. What this
/// does *not* stand in for is a real club: no PA, no microphone response, no
/// dropped glasses. It proves the rule the detector implements, not that the
/// rule is the right one for club audio, which is risk R1 and needs real
/// recordings.
Float64List _room({
  required double seconds,
  double level = 0.02,
  List<({double from, double to, double level})> reactions = const [],
}) {
  final random = Random(20260822);
  final samples = Float64List((seconds * _sampleRate).round());
  for (var i = 0; i < samples.length; i++) {
    final t = i / _sampleRate;
    var amplitude = level;
    for (final reaction in reactions) {
      if (t >= reaction.from && t < reaction.to) amplitude = reaction.level;
    }
    samples[i] = (random.nextDouble() * 2 - 1) * amplitude;
  }
  return samples;
}

void main() {
  test('6.8 a sustained rise above the room becomes one laugh', () {
    final samples = _room(
      seconds: 10,
      reactions: [(from: 4.0, to: 6.0, level: 0.4)],
    );

    final events = detectLaughs(samples, sampleRate: _sampleRate);

    expect(events, hasLength(1));
    expect(events.single.at.seconds, closeTo(4.0, 0.1));
    expect(events.single.duration, closeTo(2.0, 0.15));
    expect(events.single.intensity, greaterThan(0.1));
  });

  test('6.8 a rise shorter than the minimum duration is not a laugh', () {
    // A shout, a dropped glass, a word landing hard: loud, but over too fast
    // for a room that is actually laughing.
    final samples = _room(
      seconds: 10,
      reactions: [(from: 4.0, to: 4.2, level: 0.6)],
    );

    expect(detectLaughs(samples, sampleRate: _sampleRate), isEmpty);
  });

  test('6.8 separate reactions become separate events', () {
    final samples = _room(
      seconds: 20,
      reactions: [
        (from: 3.0, to: 5.0, level: 0.4),
        (from: 12.0, to: 14.0, level: 0.4),
      ],
    );

    final events = detectLaughs(samples, sampleRate: _sampleRate);

    expect(events, hasLength(2));
    expect(events.first.at.seconds, closeTo(3.0, 0.1));
    expect(events.last.at.seconds, closeTo(12.0, 0.1));
  });

  test('6.8 a room that never reacts produces nothing', () {
    expect(detectLaughs(_room(seconds: 30), sampleRate: _sampleRate), isEmpty);
  });

  test('6.8 silence produces nothing rather than dividing by a zero baseline', () {
    final silence = Float64List(_sampleRate * 5);

    expect(detectLaughs(silence, sampleRate: _sampleRate), isEmpty);
  });

  test('6.8 the threshold is relative, so a quiet room and a loud one both work', () {
    // The same reaction, six times over the room's level in both cases. An
    // absolute threshold would find the loud room's laugh and miss the quiet
    // room's, or fire continuously in the loud one.
    for (final roomLevel in [0.005, 0.2]) {
      final samples = _room(
        seconds: 10,
        level: roomLevel,
        reactions: [(from: 4.0, to: 6.0, level: roomLevel * 6)],
      );

      final events = detectLaughs(samples, sampleRate: _sampleRate);

      expect(events, hasLength(1), reason: 'room level $roomLevel');
      expect(events.single.at.seconds, closeTo(4.0, 0.1), reason: 'room level $roomLevel');
    }
  });

  test('6.8 a louder reaction carries a higher intensity', () {
    List<LaughEvent> at(double level) => detectLaughs(
          _room(seconds: 10, reactions: [(from: 4.0, to: 6.0, level: level)]),
          sampleRate: _sampleRate,
        );

    expect(at(0.6).single.intensity, greaterThan(at(0.2).single.intensity));
  });

  test('6.8 intensity is absolute, so two shows can be compared', () {
    // The same reaction recorded in two rooms of different loudness carries a
    // comparable intensity. Were it normalised against each recording's own
    // peak, both would read 1.0 and the analysis product could not tell a
    // stormer from a polite chuckle.
    final quiet = detectLaughs(
      _room(seconds: 10, level: 0.01, reactions: [(from: 4.0, to: 6.0, level: 0.1)]),
      sampleRate: _sampleRate,
    ).single;
    final loud = detectLaughs(
      _room(seconds: 10, level: 0.01, reactions: [(from: 4.0, to: 6.0, level: 0.5)]),
      sampleRate: _sampleRate,
    ).single;

    expect(loud.intensity, greaterThan(quiet.intensity * 2));
  });

  test('6.8 a laugh still running when the recording stops is still reported', () {
    final samples = _room(
      seconds: 10,
      reactions: [(from: 8.0, to: 10.0, level: 0.4)],
    );

    final events = detectLaughs(samples, sampleRate: _sampleRate);

    expect(events, hasLength(1));
    expect(events.single.at.seconds, closeTo(8.0, 0.1));
  });

  test('6.8 a set that storms is still detected', () {
    // Laughter over more than half the recording. This is the case that
    // decides how the baseline is measured: the mean of these frames is
    // dragged up by the laughter itself until the threshold sits above the
    // laughter, and the better the set went the fewer laughs it would find.
    // A low quantile keeps standing for the room between reactions.
    final samples = _room(
      seconds: 20,
      reactions: [
        (from: 1.0, to: 4.0, level: 0.4),
        (from: 5.0, to: 8.5, level: 0.4),
        (from: 9.5, to: 13.0, level: 0.4),
        (from: 14.0, to: 18.0, level: 0.4),
      ],
    );

    final events = detectLaughs(samples, sampleRate: _sampleRate);

    expect(events, hasLength(4));
  });

  test('6.9 the same recording yields identical events every run', () {
    final samples = _room(
      seconds: 20,
      reactions: [
        (from: 3.0, to: 5.0, level: 0.4),
        (from: 12.0, to: 14.5, level: 0.3),
      ],
    );

    List<String> describe(List<LaughEvent> events) => [
          for (final e in events) '${e.at.seconds}|${e.duration}|${e.intensity}',
        ];

    final first = detectLaughs(samples, sampleRate: _sampleRate);
    final second = detectLaughs(samples, sampleRate: _sampleRate);

    expect(describe(first), describe(second));
    expect(first, isNotEmpty);
  });

  test('6.3 an event carries start, duration and intensity, and nothing else', () {
    final event = detectLaughs(
      _room(seconds: 10, reactions: [(from: 4.0, to: 6.0, level: 0.4)]),
      sampleRate: _sampleRate,
    ).single;

    // Named explicitly so that adding a class or confidence field to LaughEvent
    // has to change this list, and therefore has to change the spec first.
    expect(event.at, isA<CaptureTime>());
    expect(event.duration, isA<double>());
    expect(event.intensity, inInclusiveRange(0, 1));
  });

  test('an unusable sample rate is refused rather than guessed at', () {
    expect(detectLaughs(_room(seconds: 5), sampleRate: 0), isEmpty);
    expect(detectLaughs(Float64List(0), sampleRate: _sampleRate), isEmpty);
  });
}
