import 'dart:async';

import 'package:setlist_core/setlist_core.dart';

/// A scripted recorder that records what the app asked of it.
///
/// This is the boundary of what the `behavior` kind can prove: a case confirms
/// the app *asks* for a recording of the right shape, never that a platform
/// delivers one. Requirement 6.5 is a tracked gap for exactly this reason —
/// no fake can stand in for an audio session surviving a locked screen.
class FakeRecordingSession implements RecordingSession {
  final _events = StreamController<RecordingEvent>.broadcast();

  /// Every path the app asked to write to, in order.
  final List<String> started = [];
  int stops = 0;
  double _captured = 0;
  bool _running = false;

  @override
  double get captured => _captured;

  @override
  bool get isRunning => _running;

  @override
  Stream<RecordingEvent> get events => _events.stream;

  @override
  Future<void> start({required String path}) async {
    started.add(path);
    _running = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    _running = false;
  }

  /// What a platform recorder would report while running.
  void emit(RecordingEvent event) => _events.add(event);

  /// Time passes only while something is being written: the capture clock
  /// counts recorded audio, not wall time, so it never advances across a gap
  /// where nothing was captured.
  void recordSeconds(double seconds) {
    if (_running) _captured += seconds;
  }
}
