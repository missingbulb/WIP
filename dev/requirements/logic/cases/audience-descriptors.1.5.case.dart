import 'dart:convert';

import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 1.5 — A show carries structured audience descriptors, each independently
/// unknown.
final audienceDescriptors_1_5 = RequirementCase('1.5', (tester) {
  const partial = Audience(seating: Seating.seated);

  expectAbsent(partial.size, 'an unset size');
  expectAbsent(partial.service, 'an unset service');
  expectAbsent(partial.crowd, 'an unset crowd');
  expectThat(partial.seating, Seating.seated, 'while the one that is set is kept');

  // "unknown size, seated" and "0 people, seated" are different facts, and the
  // analysis product would draw different conclusions from them.
  expectFalse(
    partial == const Audience(size: 0, seating: Seating.seated),
    'an unknown size is not an empty room',
  );

  final back = Audience.fromJson(
    json.decode(json.encode(const Audience(size: 80, crowd: Crowd.publicRoom).toJson()))
        as Map<String, dynamic>,
  );
  expectThat(back.size, 80, 'a known descriptor survives the round trip');
  expectAbsent(back.seating, 'and an absent one does not become a default');

  expectAbsent(
    Audience.fromJson(const {'seating': 'hammocks'}).seating,
    'a value this build does not recognise is unknown, not the first option',
  );
});
