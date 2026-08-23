import 'dart:io';

import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 1.6 — The library survives app relaunch: jokes, sets and shows written in
/// one session are read back in the next.
final librarySurvivesRelaunch_1_6 = RequirementCase('1.6', (tester) async {
  // Real file I/O only completes outside the fake-async test zone: inside it,
  // the future never resolves and the case hangs until its timeout.
  await tester.runAsync(() async {
    final container = await Directory.systemTemp.createTemp('setlist-relaunch');
    try {
    await FileLibraryStore.inContainer(container).save(
      Library(
        jokes: [
          Joke(
            id: 'airport',
            title: 'Airport security',
            body: 'Shoes off.',
            estimatedLength: const Duration(seconds: 145),
          ),
        ],
        sets: [SetList(id: 'fri', name: 'Fri late', jokeIds: ['airport'])],
        shows: [
          Show(
            id: 'stand',
            venue: 'The Stand',
            startedAt: DateTime.utc(2026, 8, 21, 22, 30),
            plannedLength: const Duration(minutes: 20),
            audience: const Audience(size: 80, seating: Seating.seated),
          ),
        ],
      ),
    );

    // A second store over the same container is the next launch.
    final read = await FileLibraryStore.inContainer(container).load();

    expectThat(read.jokes.single.title, 'Airport security', 'the material is still there');
    expectThat(
      read.jokes.single.estimatedLength,
      const Duration(seconds: 145),
      'with its estimate intact',
    );
    expectThat(read.sets.single.jokeIds, ['airport'], 'the set still names its jokes');
    expectThat(read.shows.single.venue, 'The Stand', 'and the show still knows the room');
    expectThat(read.shows.single.audience.size, 80, 'including who was in it');
    } finally {
      await container.delete(recursive: true);
    }
  });
});
