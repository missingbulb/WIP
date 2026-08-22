import 'package:setlist_core/setlist_core.dart';
import 'package:test/test.dart';

void main() {
  group('timeline', () {
    test('orders taps and laughs on the one clock they share', () {
      final ordered = timeline(
        taps: [
          TapEvent(at: const CaptureTime(10), jokeId: 'van'),
          TapEvent(at: const CaptureTime(0), jokeId: 'opener'),
        ],
        laughs: [
          const LaughEvent(at: CaptureTime(4), duration: 2, intensity: 0.6),
        ],
      );

      expect(ordered.map((e) => e.at.seconds), [0, 4, 10]);
    });

    test('puts a tap before a laugh stamped at the same instant', () {
      // The laugh a bit opens on must belong to that bit, not to the one that
      // just ended — which is decided entirely by this tie-break.
      final ordered = timeline(
        taps: [TapEvent(at: const CaptureTime(8), jokeId: 'airport')],
        laughs: [const LaughEvent(at: CaptureTime(8), duration: 1, intensity: 0.9)],
      );

      expect(ordered.first, isA<TapEvent>());
      expect(ordered.last, isA<LaughEvent>());
    });
  });
}
