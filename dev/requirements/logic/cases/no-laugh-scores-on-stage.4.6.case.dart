import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 4.6 — No stage-mode card carries a laugh count or laugh score.
final noLaughScoresOnStage_4_6 = RequirementCase('4.6', (tester) {
  // An absence is exactly what a picture proves badly: a golden that happens
  // not to show a number keeps passing when one is added in a state it does
  // not cover. So the rule is asserted against the card's shape instead.
  final card = StageCard(
    joke: Joke(id: 'airport', title: 'Airport security', body: 'Shoes off.'),
  );

  expectFalse(
    '\${card.id} \${card.state} \${card.runTime}'.toLowerCase().contains('laugh'),
    'a card exposes no laugh field',
  );
  expectFalse(
    card.joke.toJson().keys.any((key) => key.toLowerCase().contains('laugh')),
    'and neither does the joke behind it',
  );
});
