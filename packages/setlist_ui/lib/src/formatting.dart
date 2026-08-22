/// `m:ss`, the only time format the stage screen uses.
///
/// Truncates rather than rounds: a clock that reads 1:24 must keep reading 1:24
/// for the whole of that second, and a comedian glancing at it twice must never
/// see it go backwards.
String clock(Duration time) {
  final whole = time.inSeconds;
  final minutes = whole ~/ 60;
  final seconds = (whole % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// The countdown, which reads as a negative until the slot is spent and then
/// counts up.
///
/// The leading character is a true minus sign (U+2212), not a hyphen: it is
/// what the spec pins at requirement 2.5, and it is what sits at the same
/// optical weight as the plus it turns into.
String countdown(Duration remaining) =>
    remaining.isNegative ? '+${clock(-remaining)}' : '−${clock(remaining)}';
