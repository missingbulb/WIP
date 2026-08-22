import 'package:setlist_core/setlist_core.dart';

import 'stage_screen.dart';

/// The set every screen case renders: the mockup's nine bits, mid-show.
///
/// One fixture across the screen kind means the goldens differ only where the
/// requirement under test differs. Ids are fixed rather than generated, because
/// a golden of a generated id would differ on every run.
abstract final class StageFixture {
  static const venue = 'The Stand · Fri late';
  static const slot = Duration(minutes: 20);

  /// The mockup's moment: 8:27 into the set.
  static const midShowElapsed = Duration(minutes: 8, seconds: 27);

  static List<Joke> get jokes => [
        Joke(
          id: 'crowd-work',
          title: 'Crowd work',
          body: 'Every room has one man who answers a rhetorical question. '
              'Tonight it is you, and the whole room has noticed.',
          estimatedLength: const Duration(seconds: 190),
        ),
        Joke(
          id: 'dads-van',
          title: "Dad's van",
          body: 'My dad drove a van with no back seats, so my childhood was spent '
              'sliding around in the boot like unsecured cargo, which is legally what I was.',
          estimatedLength: const Duration(seconds: 125),
        ),
        Joke(
          id: 'flatmate-rota',
          title: 'Flatmate rota',
          body: 'We have a cleaning rota on the fridge. It has been there two years. '
              'It is the cleanest thing in the flat.',
          estimatedLength: const Duration(seconds: 110),
        ),
        Joke(
          id: 'airport-security',
          title: 'Airport security',
          body: 'They make you take off your shoes but not your socks — which tells me '
              'the threat level is exactly one layer deep.',
          setups: const [SetupSpan(start: 0, length: 52)],
          notes: const ["…beat… I've been wearing the same socks since Tuesday."],
          tags: const ['alt tag: TSA loyalty card', 'cut if short'],
          estimatedLength: const Duration(seconds: 145),
        ),
        Joke(
          id: 'gym-induction',
          title: 'Gym induction',
          body: 'The induction guy asked what my goals were and I said stairs, '
              'and then he wrote it down, which was worse.',
          estimatedLength: const Duration(seconds: 150),
        ),
        Joke(
          id: 'wedding-speech',
          title: 'Wedding speech',
          body: 'I was asked to do a reading at a wedding, which is what you say to '
              'someone you like but would not trust with a microphone.',
          estimatedLength: const Duration(seconds: 180),
        ),
        Joke(
          id: 'nans-ipad',
          title: "Nan's iPad",
          body: 'My nan holds her iPad like it is a hostage situation and she is the negotiator.',
          estimatedLength: const Duration(seconds: 100),
        ),
        Joke(
          id: 'dating-apps',
          title: 'Dating apps',
          body: 'My profile says I like long walks, which is true, because I cannot '
              'afford anywhere to go.',
          estimatedLength: const Duration(seconds: 135),
        ),
        Joke(
          id: 'closer-ferry',
          title: 'Closer — the ferry',
          body: 'The last ferry leaves at eleven, so every romance on that island '
              'has a hard deadline.',
          estimatedLength: const Duration(seconds: 160),
        ),
      ];

  /// Three bits told, the fourth live for 1:24, five queued — the mockup's
  /// moment.
  static StageModel midShow({bool autodetectAvailable = false}) {
    final model = StageModel(
      jokes: jokes,
      plannedLength: slot,
      autodetectAvailable: autodetectAvailable,
    );
    model.tapCard(jokeId: 'crowd-work', at: const CaptureTime(0));
    model.tapCard(jokeId: 'dads-van', at: const CaptureTime(190));
    model.tapCard(jokeId: 'flatmate-rota', at: const CaptureTime(315));
    model.tapCard(jokeId: 'airport-security', at: const CaptureTime(423));
    return model;
  }

  /// The set as it stands before the comedian taps anything: everything queued,
  /// the recording already running.
  static StageState beforeTheFirstTap() => StageState(
        model: StageModel(jokes: jokes, plannedLength: slot),
        venue: venue,
        elapsed: Duration.zero,
      );

  static StageState state({
    Duration elapsed = midShowElapsed,
    double laughLevel = 0,
    bool isRecording = true,
    StageModel? model,
  }) =>
      StageState(
        model: model ?? midShow(),
        venue: venue,
        elapsed: elapsed,
        laughLevel: laughLevel,
        isRecording: isRecording,
      );
}
