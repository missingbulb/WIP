/// The product's platform-independent core.
///
/// Everything here is pure Dart by rule, not by accident: the stage state
/// machine, the capture timeline and laugh detection are the parts of the
/// product that must behave identically on every platform, so nothing in this
/// package may import `dart:ui`, Flutter, or any platform channel. What the
/// platform does own — the microphone — reaches this package only as the
/// recording contract the app implements for it.
library setlist_core;

export 'src/capture.dart';
