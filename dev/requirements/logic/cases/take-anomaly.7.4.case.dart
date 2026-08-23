import 'package:setlist_core/setlist_core.dart';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

Take _take(double seconds) => Take(
      jokeId: 'airport',
      showId: 'show',
      peakLaughDuration: Duration(milliseconds: (seconds * 1000).round()),
    );

/// 7.4 — A take is flagged anomalous when its peak laugh duration falls at
/// least two standard deviations below the mean of the joke's other takes, and
/// never when fewer than three other takes exist.
final takeAnomaly_7_4 = RequirementCase('7.4', (tester) {
  // Real spread among the comparison takes: with a tight set, a take only
  // slightly below the mean is genuinely several sigma out, and "merely
  // underperforms" would have nothing to say.
  final others = [_take(6.0), _take(5.0), _take(7.0), _take(6.0)];

  expectTrue(
    TakeAnomaly.isAnomalous(_take(2.0), amongOthers: others),
    'a take far below the rest is flagged',
  );
  expectFalse(
    TakeAnomaly.isAnomalous(_take(5.2), amongOthers: others),
    'a take that merely underperforms is not',
  );
  expectFalse(
    TakeAnomaly.isAnomalous(_take(30.0), amongOthers: others),
    'and neither is one far above the rest — the flag is for a bit that died',
  );

  // Two takes with real spread: identical ones would be refused by the
  // zero-deviation rule instead, and the count would never be consulted.
  expectAbsent(
    TakeAnomaly.deviation(_take(0.1), amongOthers: [_take(6.0), _take(2.0)]),
    'two other takes cannot establish a norm',
  );
  expectTrue(
    TakeAnomaly.deviation(_take(0.1), amongOthers: [_take(6.0), _take(2.0), _take(5.0)]) != null,
    'a third makes the same take judgeable',
  );

  expectAbsent(
    TakeAnomaly.deviation(_take(5.9), amongOthers: [_take(6.0), _take(6.0), _take(6.0)]),
    'takes with no spread are no signal, not an infinitely strong one',
  );
});
