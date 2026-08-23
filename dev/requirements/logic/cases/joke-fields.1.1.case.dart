import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 1.1 — A joke carries a title, body text, delivery notes, tags, callback
/// references and an estimated length.
final jokeFields_1_1 = RequirementCase('1.1', (tester) {
  final joke = Joke(
    title: 'Airport security',
    body: 'They make you take off your shoes.',
    setups: const [SetupSpan(start: 5, length: 4)],
    notes: const ['...beat...'],
    tags: const ['travel'],
    callbacks: const ['dads-van'],
    estimatedLength: const Duration(seconds: 145),
  );

  expectThat(joke.title, 'Airport security', 'a joke carries its title');
  expectThat(joke.body, 'They make you take off your shoes.', 'a joke carries its body');
  expectThat(joke.setups.length, 1, 'a joke carries its crucial setups');
  expectThat(joke.notes, ['...beat...'], 'a joke carries its delivery notes');
  expectThat(joke.tags, ['travel'], 'a joke carries its tags');
  expectThat(joke.callbacks, ['dads-van'], 'a joke carries what it calls back to');
  expectThat(joke.estimatedLength, const Duration(seconds: 145), 'a joke carries its estimate');

  expectAbsent(
    Joke(title: 'New bit', body: 'Untried.').estimatedLength,
    'an unestimated joke has no length',
  );
});
