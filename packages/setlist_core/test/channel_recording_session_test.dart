import 'dart:async';

import 'package:setlist_core/setlist_core.dart';
import 'package:test/test.dart';

void main() {
  late StreamController<Map<String, Object?>> platform;
  late List<String> calls;
  late ChannelRecordingSession session;

  setUp(() {
    platform = StreamController<Map<String, Object?>>.broadcast();
    calls = [];
    session = ChannelRecordingSession(
      invoke: (method, [arguments]) async {
        calls.add('$method ${arguments ?? {}}');
        return null;
      },
      events: platform.stream,
    );
  });

  tearDown(() async {
    await session.dispose();
    await platform.close();
  });

  test('start hands the platform the path to write', () async {
    await session.start(path: '/container/shows/s/part-0.m4a');

    expect(calls.single, contains('/container/shows/s/part-0.m4a'));
    expect(session.isRunning, isTrue);
  });

  test('the clock comes from the platform, not from elapsed time', () async {
    // Only the recorder knows how much audio actually reached the file, and
    // that is what a card tap's timestamp has to index into.
    await session.start(path: '/p.m4a');
    platform.add({'type': 'level', 'level': 0.4, 'captured': 12.5});
    await Future<void>.delayed(Duration.zero);

    expect(session.captured, 12.5);
  });

  test('a level reading reaches the app clamped to 0..1', () async {
    final levels = <double>[];
    session.events.listen((e) {
      if (e is RecordingLevel) levels.add(e.level);
    });

    platform.add({'type': 'level', 'level': 1.4});
    platform.add({'type': 'level', 'level': -0.2});
    await Future<void>.delayed(Duration.zero);

    expect(levels, [1.0, 0.0]);
  });

  test('6.6 an interruption stops the session and names its cause', () async {
    final seen = <RecordingEvent>[];
    session.events.listen(seen.add);
    await session.start(path: '/p.m4a');

    platform.add({'type': 'interrupted', 'cause': 'microphoneTaken'});
    await Future<void>.delayed(Duration.zero);

    expect(session.isRunning, isFalse);
    expect((seen.single as RecordingInterrupted).cause, InterruptionCause.microphoneTaken);
  });

  test('6.6 an unnamed cause is sessionLost, never a guess at which app took it', () async {
    final seen = <RecordingEvent>[];
    session.events.listen(seen.add);

    platform.add({'type': 'interrupted'});
    await Future<void>.delayed(Duration.zero);

    expect((seen.single as RecordingInterrupted).cause, InterruptionCause.sessionLost);
  });

  test('6.6 resuming marks the session running again', () async {
    await session.start(path: '/p.m4a');
    platform.add({'type': 'interrupted', 'cause': 'sessionLost'});
    await Future<void>.delayed(Duration.zero);

    platform.add({'type': 'resumed'});
    await Future<void>.delayed(Duration.zero);

    expect(session.isRunning, isTrue);
  });

  test('6.7 no platform event can carry audio into the app', () async {
    // The seam has no case for samples at all: requirement 6.7 is structural
    // here rather than promised. An event carrying them is simply ignored.
    final seen = <RecordingEvent>[];
    session.events.listen(seen.add);

    platform.add({'type': 'samples', 'pcm': [0.1, 0.2, 0.3]});
    await Future<void>.delayed(Duration.zero);

    expect(seen, isEmpty);
  });
}
