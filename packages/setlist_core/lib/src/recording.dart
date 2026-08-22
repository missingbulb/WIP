import 'capture.dart';

/// Why a recording stopped being written, when it was not the app's doing.
enum InterruptionCause {
  /// Something with a stronger claim took the microphone — a call, or another
  /// app the platform let through.
  microphoneTaken,

  /// The platform reclaimed the audio session for a reason it did not name.
  sessionLost,
}

/// What the recorder tells the rest of the app while it runs.
sealed class RecordingEvent {
  const RecordingEvent();
}

/// The current input level, 0..1, for the stage screen's laugh strip.
///
/// A meter reading, never the audio itself: nothing analyses while capture is
/// running (requirement 6.7), so this exists to be *drawn*, and no laugh event
/// is ever derived from it.
class RecordingLevel extends RecordingEvent {
  const RecordingLevel(this.level);
  final double level;
}

/// The recording stopped without being asked to. The part so far is closed.
class RecordingInterrupted extends RecordingEvent {
  const RecordingInterrupted(this.cause);
  final InterruptionCause cause;
}

/// The platform handed the microphone back.
class RecordingResumed extends RecordingEvent {
  const RecordingResumed();
}

/// The recording session the coordinator drives.
///
/// The whole platform surface of the product, and deliberately this small: with
/// nothing analysing during capture (D8), neither platform needs to hand raw
/// audio to Dart, so what crosses the boundary is commands down and small
/// events up. The shipping implementations wrap AVAudioRecorder and
/// MediaRecorder (D10).
///
/// The requirement cases drive a fake, so what they prove is that this code
/// *asks* for the right thing — never that the platform performs it. That gap
/// closes on a device, not in CI.
abstract interface class RecordingSession {
  /// Seconds of audio captured so far: the monotonic source card taps and
  /// laugh events are both stamped against.
  ///
  /// Counts recorded audio, not wall time, so it never rewinds and never
  /// advances across a gap when nothing was being written.
  double get captured;

  bool get isRunning;

  /// Level readings and interruption transitions, in the order they happened.
  Stream<RecordingEvent> get events;

  Future<void> start({required String path});

  Future<void> stop();
}

/// Owns the recording for one show: when it runs, where its audio goes, and the
/// clock everything else timestamps against.
class CaptureCoordinator {
  CaptureCoordinator({required this.session, required this.containerPath});

  final RecordingSession session;

  /// The directory the recording is written inside. Everything here is deleted
  /// when the user deletes the app.
  final String containerPath;

  /// One file per uninterrupted stretch of recording. A show with no
  /// interruption has exactly one.
  final List<String> parts = [];

  String? _showId;
  String? get showId => _showId;

  bool get isRecording => session.isRunning;

  /// The instant to stamp a card tap with.
  CaptureTime get now => CaptureTime(session.captured);

  Future<void> startShow(String showId) async {
    _showId = showId;
    parts.clear();
    await _startPart(showId);
  }

  /// The audio session was taken away. The stretch so far is closed rather than
  /// abandoned, so nothing captured before the interruption is lost.
  Future<void> interruptionBegan() async {
    if (!session.isRunning) return;
    await session.stop();
  }

  /// The audio session came back. The show continues into a new stretch; the
  /// clock never rewinds, so timestamps stay comparable across the gap.
  Future<void> interruptionEnded() async {
    final showId = _showId;
    if (showId == null || session.isRunning) return;
    await _startPart(showId);
  }

  /// Ends the show and hands back its audio, in order.
  Future<List<String>> endShow() async {
    if (session.isRunning) await session.stop();
    _showId = null;
    return [...parts];
  }

  /// Takes the show rather than reading the field, so there is exactly one
  /// place that decides whether a show is in progress.
  Future<void> _startPart(String showId) async {
    // AAC in an MPEG-4 container: the format the architecture's ~60 MB hour is
    // sized for.
    final path = '$containerPath/shows/$showId/part-${parts.length}.m4a';
    await session.start(path: path);
    parts.add(path);
  }
}
