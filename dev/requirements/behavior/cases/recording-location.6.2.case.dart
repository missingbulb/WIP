import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/fake_world.dart';
import '../../shared/requirement_case.dart';

/// 6.2 — The recording is written as AAC into the app's own container, in a
/// location the user can delete.
final recordingLocation_6_2 = RequirementCase('6.2', (tester) async {
  final session = FakeRecordingSession();
  final capture = CaptureCoordinator(session: session, containerPath: '/container');

  await capture.startShow('show-1');

  final path = session.started.single;
  expectTrue(
    path.startsWith('/container/'),
    'everything written lives inside the container the user deletes with the app',
  );
  expectTrue(path.endsWith('.m4a'), 'AAC in an MPEG-4 container');
  expectTrue(path.contains('show-1'), 'filed under the show it belongs to');
});
