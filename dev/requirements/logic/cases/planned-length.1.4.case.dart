import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 1.4 — A set's planned length is the sum of its jokes' estimated lengths.
final plannedLength_1_4 = RequirementCase('1.4', (tester) {
  final library = Library(
    jokes: [
      Joke(id: 'a', title: 'A', body: '', estimatedLength: const Duration(seconds: 90)),
      Joke(id: 'b', title: 'B', body: '', estimatedLength: const Duration(seconds: 150)),
      Joke(id: 'c', title: 'C', body: ''),
    ],
    sets: [SetList(id: 's', name: 'Set', jokeIds: ['a', 'b'])],
  );
  final set = library.sets.first;

  expectThat(library.plannedLength(set), const Duration(seconds: 240), 'the estimates are summed');

  set.jokeIds.add('c');
  expectThat(
    library.plannedLength(set),
    const Duration(seconds: 240),
    'a joke with no estimate contributes nothing rather than a guess',
  );

  set.jokeIds.add('deleted');
  expectThat(
    library.jokesOf(set).length,
    3,
    'an id with no joke behind it leaves a shorter set, not a blank card',
  );
});
