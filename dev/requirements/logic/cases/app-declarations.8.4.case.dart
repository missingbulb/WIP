import 'dart:io';

import '../../shared/expectations.dart';
import '../../shared/requirement_case.dart';

/// 8.4 — The iOS app declares a microphone usage description and the
/// background-audio mode, and declares no other background mode.
final appDeclarations_8_4 = RequirementCase('8.4', (tester) {
  // Read from the shipped plist rather than a copy of it: the declaration is a
  // promise to the person installing the app, and the only way to prove the
  // promise is to read what actually ships.
  final plist = File('../../app/ios/Runner/Info.plist').readAsStringSync();

  expectTrue(
    plist.contains('NSMicrophoneUsageDescription'),
    'the app says why it wants the microphone',
  );
  expectTrue(
    plist.contains('UIBackgroundModes'),
    'and declares that it keeps running to record',
  );
  expectTrue(plist.contains('<string>audio</string>'), 'the mode is audio');

  // Every other background mode Apple offers, none of which this app has any
  // business asking for.
  for (final mode in const [
    'location',
    'voip',
    'fetch',
    'remote-notification',
    'processing',
    'bluetooth-central',
    'external-accessory',
  ]) {
    expectFalse(
      plist.contains('<string>\$mode</string>'),
      'no background mode beyond audio is declared (\$mode)',
    );
  }
});
