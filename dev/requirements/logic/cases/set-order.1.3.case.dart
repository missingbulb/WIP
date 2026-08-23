import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 1.3 — A set is an ordered list of jokes; reordering changes positions only,
/// never joke identity.
final setOrder_1_3 = RequirementCase('1.3', (tester) {
  final set = SetList(name: 'Fri late', jokeIds: ['opener', 'van', 'closer']);

  set.move(from: 2, to: 0);

  expectThat(set.jokeIds, ['closer', 'opener', 'van'], 'the order changes');
  expectThat(set.jokeIds.toSet(), {'opener', 'van', 'closer'}, 'the same jokes are still in it');
});
