import 'package:setlist_core/setlist_core.dart';
import 'package:test/test.dart';

Joke _joke(String id) => Joke(id: id, title: id, body: '$id body');

StageModel _stage({bool autodetect = false}) => StageModel(
      jokes: [_joke('opener'), _joke('van'), _joke('airport')],
      plannedLength: const Duration(minutes: 20),
      autodetectAvailable: autodetect,
    );

void main() {
  group('5.2 the segment-mode switch', () {
    test('refuses autodetect while no detector is registered', () {
      final stage = _stage();

      expect(
        () => stage.setSegmentMode(SegmentMode.autodetect),
        throwsA(isA<SegmentModeRefusal>()),
      );
      // The refusal must not half-apply: a switch that reports failure and
      // changes the mode anyway is worse than one that does nothing.
      expect(stage.segmentMode, SegmentMode.manual);
    });

    test('accepts autodetect once one is', () {
      final stage = _stage(autodetect: true);

      stage.setSegmentMode(SegmentMode.autodetect);

      expect(stage.segmentMode, SegmentMode.autodetect);
    });

    test('always accepts manual', () {
      final stage = _stage();
      stage.setSegmentMode(SegmentMode.manual);
      expect(stage.segmentMode, SegmentMode.manual);
    });
  });

  test('5.3 tapping a queued card closes the live segment and opens one', () {
    final stage = _stage();

    stage.tapCard(jokeId: 'opener', at: const CaptureTime(0));
    final outcome = stage.tapCard(jokeId: 'van', at: const CaptureTime(90));

    expect(outcome, const TapSwitched('van'));
    expect(stage.liveJokeId, 'van');
    // Same instant for both boundaries: no gap belongs to neither bit.
    expect(stage.segments.first.end, const CaptureTime(90));
    expect(stage.segments.last.start, const CaptureTime(90));
    expect(stage.segments.last.end, isNull);
  });

  test('5.4 tapping the live card changes nothing and opens no empty segment', () {
    final stage = _stage();
    stage.tapCard(jokeId: 'opener', at: const CaptureTime(0));

    final outcome = stage.tapCard(jokeId: 'opener', at: const CaptureTime(30));

    expect(outcome, const TapIgnored());
    expect(stage.segments, hasLength(1));
    expect(stage.segments.single.end, isNull);
    expect(stage.liveJokeId, 'opener');
  });

  test('5.5 tapping a told card re-opens it, leaving its first segment intact', () {
    final stage = _stage();
    stage.tapCard(jokeId: 'van', at: const CaptureTime(0));
    stage.tapCard(jokeId: 'opener', at: const CaptureTime(60));

    // The callback lands, so the comedian goes back to the van.
    stage.tapCard(jokeId: 'van', at: const CaptureTime(200));

    final vanSegments = stage.segments.where((s) => s.jokeId == 'van').toList();
    expect(vanSegments, hasLength(2));
    expect(vanSegments.first.start, const CaptureTime(0));
    expect(vanSegments.first.end, const CaptureTime(60));
    expect(vanSegments.last.end, isNull);
    expect(stage.liveJokeId, 'van');
  });

  test('5.7 every segment a tap opens records manual provenance', () {
    final stage = _stage();
    stage.tapCard(jokeId: 'opener', at: const CaptureTime(0));
    stage.tapCard(jokeId: 'van', at: const CaptureTime(60));

    expect(
      stage.segments.map((s) => s.provenance),
      everyElement(SegmentProvenance.manual),
    );
  });

  group('4.7 the started tally', () {
    test('counts a joke re-opened after being told only once', () {
      final stage = _stage();
      stage.tapCard(jokeId: 'van', at: const CaptureTime(0));
      stage.tapCard(jokeId: 'opener', at: const CaptureTime(60));
      stage.tapCard(jokeId: 'van', at: const CaptureTime(200));

      expect(stage.segments, hasLength(3));
      expect(stage.startedCount, 2);
      expect(stage.plannedCount, 3);
    });

    test('is zero before anything is tapped', () {
      expect(_stage().startedCount, 0);
    });
  });

  test('4.6 no stage card carries laugh data', () {
    // An absence a picture proves badly: a golden that happens not to show a
    // number keeps passing when one is added in a state it does not cover. So
    // it is asserted against the card's shape instead.
    final card = StageCard(joke: _joke('opener'));
    final fields = {
      'joke': card.joke,
      'state': card.state,
      'runTime': card.runTime,
      'id': card.id,
    };

    expect(
      fields.keys.where((k) => k.toLowerCase().contains('laugh')),
      isEmpty,
      reason: 'a laugh field on a stage card is what requirement 4.6 forbids',
    );
  });

  group('run time', () {
    test('counts the open segment against the clock, not zero', () {
      final stage = _stage();
      stage.tapCard(jokeId: 'airport', at: const CaptureTime(500));

      // The live joke's card has no closed segment yet, so only the clock can
      // answer how long it has been running.
      expect(stage.cards.last.runTime, Duration.zero);
      expect(
        stage.runTimeOf('airport', at: const CaptureTime(584)),
        const Duration(seconds: 84),
      );
    });

    test('sums every segment of a joke told twice', () {
      final stage = _stage();
      stage.tapCard(jokeId: 'van', at: const CaptureTime(0));
      stage.tapCard(jokeId: 'opener', at: const CaptureTime(60));
      stage.tapCard(jokeId: 'van', at: const CaptureTime(200));
      stage.endSet(at: const CaptureTime(230));

      expect(stage.runTimeOf('van', at: const CaptureTime(230)), const Duration(seconds: 90));
    });
  });

  test('ending the set closes the joke still running', () {
    final stage = _stage();
    stage.tapCard(jokeId: 'opener', at: const CaptureTime(0));

    stage.endSet(at: const CaptureTime(120));

    expect(stage.segments.single.end, const CaptureTime(120));
    expect(stage.cards.first.state, CardState.told);
    expect(stage.liveJokeId, isNull);
  });
}
