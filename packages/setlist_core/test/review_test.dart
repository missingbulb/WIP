import 'package:setlist_core/setlist_core.dart';
import 'package:test/test.dart';

Take _take(double seconds) => Take(
      jokeId: 'airport',
      showId: 'show',
      peakLaughDuration: Duration(milliseconds: (seconds * 1000).round()),
    );

void main() {
  group('7.4 a take is flagged anomalous', () {
    test('when it falls at least two sigma below the rest', () {
      final others = [_take(6.0), _take(6.2), _take(5.8), _take(6.0)];
      final cold = _take(2.0);

      final deviation = TakeAnomaly.deviation(cold, amongOthers: others)!;
      expect(deviation, greaterThanOrEqualTo(2.0));
      expect(TakeAnomaly.isAnomalous(cold, amongOthers: others), isTrue);
    });

    test('never when fewer than three other takes exist', () {
      // Two takes cannot establish a norm, however far apart they are — the
      // rule refuses rather than flagging on noise. They are given real spread
      // deliberately: two *identical* takes are refused by the zero-sigma rule
      // as well, so they would pass this test without the count ever being
      // consulted.
      final others = [_take(6.0), _take(2.0)];

      expect(TakeAnomaly.deviation(_take(0.1), amongOthers: others), isNull);
      expect(TakeAnomaly.isAnomalous(_take(0.1), amongOthers: others), isFalse);
    });

    test('once a third comparison take arrives, the same take is judged', () {
      // The pair above plus one more: the only change is the count, so this is
      // what pins the threshold at three rather than two.
      final others = [_take(6.0), _take(2.0), _take(5.0)];

      expect(TakeAnomaly.deviation(_take(0.1), amongOthers: others), isNotNull);
    });

    test('never when the other takes are identical and have no spread', () {
      // Zero sigma is not an infinitely strong signal; it is no signal, and
      // dividing by it would flag every take that differs at all.
      final others = [_take(6.0), _take(6.0), _take(6.0), _take(6.0)];

      expect(TakeAnomaly.deviation(_take(5.9), amongOthers: others), isNull);
      expect(TakeAnomaly.isAnomalous(_take(5.9), amongOthers: others), isFalse);
    });

    test('not when it merely underperforms', () {
      final others = [_take(6.0), _take(5.0), _take(7.0), _take(6.0)];

      expect(TakeAnomaly.isAnomalous(_take(5.2), amongOthers: others), isFalse);
    });

    test('not when it is above the mean, however far', () {
      // The flag is for a bit that died, not one that stormed.
      final others = [_take(6.0), _take(6.2), _take(5.8), _take(6.0)];

      expect(TakeAnomaly.isAnomalous(_take(30.0), amongOthers: others), isFalse);
    });
  });

  group('2.8 the countdown', () {
    test('is neutral above three minutes remaining', () {
      expect(Countdown.tone(const Duration(minutes: 11, seconds: 33)), CountdownTone.neutral);
      expect(Countdown.tone(const Duration(minutes: 3, seconds: 1)), CountdownTone.neutral);
    });

    test('is orange at three minutes or less', () {
      expect(Countdown.tone(const Duration(minutes: 3)), CountdownTone.warning);
      expect(Countdown.tone(const Duration(minutes: 1, seconds: 18)), CountdownTone.warning);
      expect(Countdown.tone(const Duration(seconds: 1)), CountdownTone.warning);
    });

    test('is red once remaining time reaches zero', () {
      // Exactly zero is over, not the last instant of warning: the slot is
      // spent.
      expect(Countdown.tone(Duration.zero), CountdownTone.over);
      expect(Countdown.tone(const Duration(minutes: -1)), CountdownTone.over);
    });

    test('counts up once the slot is spent, rather than resting at zero', () {
      final remaining = Countdown.remaining(
        plannedLength: const Duration(minutes: 20),
        elapsed: const Duration(minutes: 21),
      );

      expect(remaining, const Duration(minutes: -1));
      expect(Countdown.tone(remaining), CountdownTone.over);
    });

    test('reads the mockup moment at 8:27 into a 20-minute slot', () {
      final remaining = Countdown.remaining(
        plannedLength: const Duration(minutes: 20),
        elapsed: const Duration(minutes: 8, seconds: 27),
      );

      expect(remaining, const Duration(minutes: 11, seconds: 33));
      expect(Countdown.tone(remaining), CountdownTone.neutral);
    });
  });
}
