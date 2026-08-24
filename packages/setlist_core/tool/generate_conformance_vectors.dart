// Writes the vectors that hold the two laugh detectors together (decision D3).
//
// The Dart detector is the authority: this tool runs it over a fixed set of
// synthesised recordings and records what it produced. Both implementations
// then assert against the committed output, so a change to either one that the
// other has not made turns a test red instead of quietly splitting the numbers
// a take is compared on.
//
// Run from the package root: dart run tool/generate_conformance_vectors.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:setlist_core/setlist_core.dart';

// Deliberately far below any real recording's rate: the detector is rate-agnostic
// (every threshold is relative and every duration is in seconds), and the vectors
// carry their samples verbatim, so a realistic rate would commit megabytes to
// prove arithmetic a few hundred frames already proves.
const _sampleRate = 500;

void main() {
  final cases = <Map<String, Object?>>[];
  for (final signal in _signals()) {
    final events = detectLaughs(signal.samples, sampleRate: _sampleRate);
    cases.add({
      'name': signal.name,
      'what': signal.what,
      'sampleRate': _sampleRate,
      'samples': base64.encode(signal.samples.buffer.asUint8List(
        signal.samples.offsetInBytes,
        signal.samples.lengthInBytes,
      )),
      'events': [
        for (final event in events)
          {
            'at': event.at.seconds,
            'duration': event.duration,
            'intensity': event.intensity,
          },
      ],
    });
  }

  final file = File('../../dev/conformance/detector-conformance.GENERATED.json');
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({
          'settings': {
            'frameMilliseconds': DetectionSettings.approved.frame.inMilliseconds,
            'minimumDurationMilliseconds':
                DetectionSettings.approved.minimumDuration.inMilliseconds,
            'thresholdOverBaseline': DetectionSettings.approved.thresholdOverBaseline,
            'baselinePercentile': DetectionSettings.approved.baselinePercentile,
          },
          'samplesEncoding': 'base64 of little-endian float64, mono, -1..1',
          'cases': cases,
        })}\n',
  );
  stdout.writeln('${cases.length} cases -> ${file.path}');
}

class _Signal {
  _Signal(this.name, this.what, this.samples);
  final String name;
  final String what;
  final Float64List samples;
}

/// Deterministic room noise: a linear congruential generator rather than
/// `Random`, so the vectors do not depend on an SDK's generator staying put.
class _Room {
  _Room(this.seed);
  int seed;
  double next() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff * 2 - 1;
  }
}

List<_Signal> _signals() {
  return [
    _Signal('silence', 'a dead room: no baseline, so nothing to report',
        Float64List(_sampleRate * 2)),
    _Signal('room-tone-only', 'a room that never reacts', _build(3.0, (t, room) => room.next() * 0.02)),
    _Signal(
      'one-laugh',
      'a two-second laugh over room tone',
      _build(6.0, (t, room) => room.next() * (t > 2.0 && t < 4.0 ? 0.4 : 0.02)),
    ),
    _Signal(
      'two-laughs',
      'two laughs with the room settling between them',
      _build(
        10.0,
        (t, room) => room.next() *
            ((t > 1.5 && t < 3.0) || (t > 6.0 && t < 8.5) ? 0.35 : 0.02),
      ),
    ),
    _Signal(
      'laugh-at-the-tail',
      'still laughing when the recording stops',
      _build(5.0, (t, room) => room.next() * (t > 3.5 ? 0.4 : 0.02)),
    ),
    _Signal(
      'shout-too-short',
      'one loud moment below the minimum duration: a dropped glass, not a laugh',
      _build(4.0, (t, room) => room.next() * (t > 2.0 && t < 2.2 ? 0.6 : 0.02)),
    ),
    _Signal(
      'just-over-threshold',
      'the room 2.6x its own baseline: a laugh, but only just — a detector '
          'calibrated a notch either way disagrees here',
      _buildExact(6.0, (t) => t > 2.0 && t < 4.0 ? 0.026 : 0.01),
    ),
    _Signal(
      'threshold-boundary-frame',
      'the room nominally exactly 2.5x its baseline: the event starts a frame '
          'late, because the frame straddling the transition averages both '
          'sides. Which way the comparison itself rounds is unobservable — no '
          'float ever lands exactly on the threshold',
      _buildExact(6.0, (t) => t > 2.0 && t < 4.0 ? 0.025 : 0.01),
    ),
    _Signal(
      'just-under-threshold',
      'the room 2.4x its baseline: not a laugh, by the same narrow margin',
      _buildExact(6.0, (t) => t > 2.0 && t < 4.0 ? 0.024 : 0.01),
    ),
    _Signal(
      'just-over-minimum-duration',
      'a reaction one frame longer than the minimum: the shortest thing that '
          'counts',
      _buildExact(4.0, (t) => t >= 1.5 && t < 2.15 ? 0.1 : 0.01),
    ),
    _Signal(
      'just-under-minimum-duration',
      'the same reaction one frame shorter: nothing to report',
      _buildExact(4.0, (t) => t >= 1.5 && t < 2.05 ? 0.1 : 0.01),
    ),
    _Signal(
      'rising-room',
      'a room that gets louder through the set without ever reacting',
      _build(8.0, (t, room) => room.next() * (0.01 + t * 0.004)),
    ),
  ];
}

/// A signal with no noise in it: every sample is the amplitude, alternating
/// sign, so a frame's RMS *is* the amplitude at that instant. The noisy signals
/// prove the detector against something recording-shaped; these prove exactly
/// where its two thresholds sit, which a noisy signal cannot — frame-to-frame
/// variance breaks a marginal run into pieces and the margin stops being the
/// thing under test.
Float64List _buildExact(double seconds, double Function(double t) amplitude) {
  final samples = Float64List((seconds * _sampleRate).round());
  for (var i = 0; i < samples.length; i++) {
    samples[i] = amplitude(i / _sampleRate) * (i.isEven ? 1 : -1);
  }
  return samples;
}

Float64List _build(double seconds, double Function(double t, _Room room) sample) {
  final room = _Room(20260824);
  final samples = Float64List((seconds * _sampleRate).round());
  for (var i = 0; i < samples.length; i++) {
    samples[i] = sample(i / _sampleRate, room);
  }
  return samples;
}
