import 'dart:async';

import 'recording.dart';

/// The Dart half of the platform recorder.
///
/// Audio never crosses this boundary. The platform writes AAC to the path it
/// is given and reports back only what the app needs to draw and to keep time:
/// seconds captured, a level, and the transitions where the microphone was
/// taken away and handed back (decision D8).
///
/// The two implementations behind it are `AVAudioRecorder` on iOS and
/// `MediaRecorder` on Android (decision D10). Neither needs raw PCM, because
/// nothing analyses during capture.
class ChannelRecordingSession implements RecordingSession {
  ChannelRecordingSession({required this.invoke, required Stream<Map<String, Object?>> events}) {
    _subscription = events.listen(_onPlatformEvent);
  }

  /// How a method reaches the platform. Injected rather than reached for, so
  /// this class is testable without a platform underneath it.
  final Future<Object?> Function(String method, [Map<String, Object?>? arguments]) invoke;

  final _events = StreamController<RecordingEvent>.broadcast();
  late final StreamSubscription<Map<String, Object?>> _subscription;

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
    await invoke('start', {'path': path});
    _running = true;
  }

  @override
  Future<void> stop() async {
    await invoke('stop');
    _running = false;
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _events.close();
  }

  void _onPlatformEvent(Map<String, Object?> event) {
    // The platform reports its own captured total rather than the app counting
    // elapsed time: only the recorder knows how much audio actually reached
    // the file, and that is what a timestamp has to index into.
    final captured = event['captured'];
    if (captured is num) _captured = captured.toDouble();

    switch (event['type']) {
      case 'level':
        final level = event['level'];
        if (level is num) _events.add(RecordingLevel(level.toDouble().clamp(0.0, 1.0)));
      case 'interrupted':
        _running = false;
        _events.add(RecordingInterrupted(
          event['cause'] == 'microphoneTaken'
              ? InterruptionCause.microphoneTaken
              : InterruptionCause.sessionLost,
        ));
      case 'resumed':
        _running = true;
        _events.add(const RecordingResumed());
    }
  }
}
