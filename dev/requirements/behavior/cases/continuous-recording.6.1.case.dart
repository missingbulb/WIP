import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/fake_world.dart';
import '../../shared/requirement_case.dart';

/// 6.1 — Recording starts when the show starts and runs unbroken to the end of
/// the set.
final continuousRecording_6_1 = RequirementCase('6.1', (tester) async {
  final session = FakeRecordingSession();
  final capture = CaptureCoordinator(session: session, containerPath: '/container');

  await capture.startShow('show-1');
  expectTrue(capture.isRecording, 'the recorder starts with the show');

  session.recordSeconds(1200);
  expectTrue(capture.isRecording, 'and is still running twenty minutes later');
  expectThat(session.started.length, 1, 'as one unbroken stretch');

  final parts = await capture.endShow();
  expectFalse(capture.isRecording, 'ending the set stops it');
  expectThat(parts.length, 1, 'and hands back the one part it wrote');
});
