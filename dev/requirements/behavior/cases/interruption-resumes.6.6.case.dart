import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/fake_world.dart';
import '../../shared/requirement_case.dart';

/// 6.6 — An audio-session interruption finalises the recording so far and
/// resumes into the same show without losing captured audio.
final interruptionResumes_6_6 = RequirementCase('6.6', (tester) async {
  final session = FakeRecordingSession();
  final capture = CaptureCoordinator(session: session, containerPath: '/container');

  await capture.startShow('show-1');
  session.recordSeconds(120);

  await capture.interruptionBegan();
  expectFalse(capture.isRecording, 'the part so far is closed rather than abandoned');

  // Nothing is being written, so nothing is being recorded: the wall clock
  // moves, the capture clock does not.
  session.recordSeconds(45);
  expectThat(capture.now.seconds, 120, 'the clock does not advance across the gap');

  await capture.interruptionEnded();
  expectTrue(capture.isRecording, 'the show continues');

  session.recordSeconds(30);
  expectThat(capture.now.seconds, 150, 'and the clock never rewinds');

  final parts = await capture.endShow();
  expectThat(parts.length, 2, 'the show is two stretches of audio, both kept');
});
