import 'dart:convert';

import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 1.2 — Crucial-setup spans marked inside a joke's body survive an
/// encode/decode round-trip with their character offsets intact.
final setupSpans_1_2 = RequirementCase('1.2', (tester) {
  final joke = Joke(
    id: 'airport',
    title: 'Airport security',
    body: 'They asked me to remove my shoes.',
    setups: const [SetupSpan(start: 5, length: 6)],
  );
  expectThat(joke.setupText(joke.setups.first), 'asked ', 'the span covers the words it marks');

  final back = Joke.fromJson(json.decode(json.encode(joke.toJson())) as Map<String, dynamic>);

  expectThat(back.setups, joke.setups, 'the spans survive the round trip');
  expectThat(back.setupText(back.setups.first), 'asked ', 'and still cover the same words');
  expectAbsent(
    back.setupText(const SetupSpan(start: 1, length: 999)),
    'a span outside the body covers nothing',
  );
});
