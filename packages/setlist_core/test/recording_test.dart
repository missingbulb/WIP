import 'dart:async';

import 'package:setlist_core/setlist_core.dart';
import 'package:test/test.dart';

/// A scripted recorder that records what the app asked of it.
///
/// It is the boundary of what these tests can prove: they confirm the app asks
/// for a recording of the right shape, never that a platform delivers one.
class FakeRecordingSession implements RecordingSession {
  final _events = StreamController<RecordingEvent>.broadcast();
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

  /// Emits what a platform recorder would report while running.
  void emit(RecordingEvent event) => _events.add(event);

  /// Time passes only while something is being written — the clock counts
  /// recorded audio, not wall time.
  void recordSeconds(double seconds) {
    if (_running) _captured += seconds;
  }
}

void main() {
  test('6.1 recording starts with the show and writes one part', () async {
    final session = FakeRecordingSession();
    final capture = CaptureCoordinator(session: session, containerPath: '/container');

    await capture.startShow('show-1');

    expect(capture.isRecording, isTrue);
    expect(session.started, ['/container/shows/show-1/part-0.m4a']);
  });

  test('6.2 the recording is written as AAC inside the app container', () async {
    final session = FakeRecordingSession();
    final capture = CaptureCoordinator(session: session, containerPath: '/container');

    await capture.startShow('show-1');

    final path = session.started.single;
    expect(path, startsWith('/container/'));
    expect(path, endsWith('.m4a'));
  });

  test('6.6 an interruption closes the part so far and resumes into a new one', () async {
    final session = FakeRecordingSession();
    final capture = CaptureCoordinator(session: session, containerPath: '/container');
    await capture.startShow('show-1');
    session.recordSeconds(120);

    await capture.interruptionBegan();
    expect(capture.isRecording, isFalse);
    expect(session.stops, 1);

    await capture.interruptionEnded();

    expect(capture.isRecording, isTrue);
    expect(session.started, [
      '/container/shows/show-1/part-0.m4a',
      '/container/shows/show-1/part-1.m4a',
    ]);
    final parts = await capture.endShow();
    expect(parts, hasLength(2));
  });

  test('6.6 the clock does not rewind across an interruption', () async {
    final session = FakeRecordingSession();
    final capture = CaptureCoordinator(session: session, containerPath: '/container');
    await capture.startShow('show-1');
    session.recordSeconds(120);

    await capture.interruptionBegan();
    // Nothing is being written, so nothing is being recorded: the wall clock
    // moves, the capture clock does not.
    session.recordSeconds(45);
    expect(capture.now.seconds, 120);

    await capture.interruptionEnded();
    session.recordSeconds(30);

    // A stamp still indexes into the audio, and still sorts after every stamp
    // taken before the gap.
    expect(capture.now.seconds, 150);
  });

  test('6.6 a second interruption while already stopped does nothing', () async {
    final session = FakeRecordingSession();
    final capture = CaptureCoordinator(session: session, containerPath: '/container');
    await capture.startShow('show-1');

    await capture.interruptionBegan();
    await capture.interruptionBegan();

    // A duplicate notification must not close a part that is already closed,
    // or the parts list grows a phantom entry on resume.
    expect(session.stops, 1);
  });

  test('6.6 a resume with no show in progress starts nothing', () async {
    final session = FakeRecordingSession();
    final capture = CaptureCoordinator(session: session, containerPath: '/container');

    await capture.interruptionEnded();

    expect(session.started, isEmpty);
    expect(capture.isRecording, isFalse);
  });

  test('6.1 ending the show stops the recorder and hands back its parts in order', () async {
    final session = FakeRecordingSession();
    final capture = CaptureCoordinator(session: session, containerPath: '/container');
    await capture.startShow('show-1');
    session.recordSeconds(60);
    await capture.interruptionBegan();
    await capture.interruptionEnded();
    session.recordSeconds(60);

    final parts = await capture.endShow();

    expect(capture.isRecording, isFalse);
    expect(parts, [
      '/container/shows/show-1/part-0.m4a',
      '/container/shows/show-1/part-1.m4a',
    ]);
    expect(capture.showId, isNull);
  });

  test('a new show does not inherit the previous show\'s parts', () async {
    final session = FakeRecordingSession();
    final capture = CaptureCoordinator(session: session, containerPath: '/container');
    await capture.startShow('show-1');
    await capture.endShow();

    await capture.startShow('show-2');

    expect(capture.parts, ['/container/shows/show-2/part-0.m4a']);
  });

  test('6.7 the seam carries a level to draw, never audio to analyse', () async {
    // The stage strip is fed by a meter reading. Nothing analyses while capture
    // runs, so there is deliberately no way for the platform to hand samples
    // across this boundary at all.
    final session = FakeRecordingSession();
    final levels = <double>[];
    final sub = session.events.listen((event) {
      if (event is RecordingLevel) levels.add(event.level);
    });
    addTearDown(sub.cancel);

    session.emit(const RecordingLevel(0.42));
    await Future<void>.delayed(Duration.zero);

    expect(levels, [0.42]);
  });
}
