import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 2.8 — The countdown is neutral above three minutes remaining, orange at
/// three minutes or less, red once remaining time reaches zero.
final countdownTone_2_8 = RequirementCase('2.8', (tester) {
  expectThat(
    Countdown.remaining(
      plannedLength: const Duration(minutes: 20),
      elapsed: const Duration(minutes: 18, seconds: 42),
    ),
    const Duration(seconds: 78),
    'remaining time',
  );
  expectThat(
    Countdown.remaining(
      plannedLength: const Duration(minutes: 20),
      elapsed: const Duration(minutes: 21),
    ),
    const Duration(minutes: -1),
    'remaining time past the slot counts up as a negative',
  );

  expectThat(Countdown.tone(const Duration(minutes: 10)), CountdownTone.neutral, 'ten minutes left');
  expectThat(
    Countdown.tone(const Duration(minutes: 3, seconds: 1)),
    CountdownTone.neutral,
    'just above the threshold',
  );
  expectThat(
    Countdown.tone(const Duration(minutes: 3)),
    CountdownTone.warning,
    'exactly at the threshold',
  );
  expectThat(
    Countdown.tone(const Duration(seconds: 78)),
    CountdownTone.warning,
    'inside the last three minutes',
  );
  expectThat(Countdown.tone(Duration.zero), CountdownTone.over, 'on the buzzer');
  expectThat(Countdown.tone(const Duration(minutes: -1)), CountdownTone.over, 'a minute over');
});
