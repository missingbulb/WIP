import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Material, MaterialType, Switch;
import 'package:setlist_core/setlist_core.dart';

import 'formatting.dart';
import 'palette.dart';
import 'stage_region.dart';

/// Everything the stage screen draws, in one value.
///
/// A screen requirement is a resting state, so the view takes state and draws
/// it — it owns no clock, no audio session and no store.
class StageState {
  const StageState({
    required this.model,
    required this.venue,
    required this.elapsed,
    this.laughLevel = 0,
    this.isRecording = true,
  });

  final StageModel model;
  final String venue;

  /// How far into the set.
  final Duration elapsed;

  /// Live laugh level, 0..1. Above [speakOverThreshold] the strip is lit.
  final double laughLevel;
  final bool isRecording;

  static const double speakOverThreshold = 0.35;

  Duration get remaining =>
      Countdown.remaining(plannedLength: model.plannedLength, elapsed: elapsed);

  StageCard? get liveCard {
    for (final card in model.cards) {
      if (card.state == CardState.live) return card;
    }
    return null;
  }

  /// A card's run time as of now — the live joke's keeps counting.
  Duration runTimeOf(StageCard card) =>
      model.runTimeOf(card.id, at: CaptureTime(elapsed.inMicroseconds / 1e6));
}

/// The live screen.
///
/// One screenful, no scrolling region: a comedian scrolling on stage has
/// already lost the room.
class StageScreen extends StatelessWidget {
  const StageScreen({
    super.key,
    required this.state,
    this.onTapCard,
    this.onSetSegmentMode,
  });

  final StageState state;
  final void Function(String jokeId)? onTapCard;
  final void Function(SegmentMode mode)? onSetSegmentMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.ink,
      // A transparent Material, purely so the switch has the ancestor its
      // implementation demands. It paints nothing of its own: the ink above is
      // still what the screen is drawn on.
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: Typeface.sans,
          color: Palette.bone,
          fontSize: 15,
        ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < narrowWidth;
              // The panel is capped when the screen is short *or* narrow, and
              // the two catch different devices: a portrait phone is narrow but
              // tall, a landscape phone is wide but short, and on both the
              // panel would otherwise take the height the set list needs.
              final short = constraints.maxHeight < shortHeight;
              final capped = narrow || short;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  _currentJoke(capped: capped, available: constraints.maxHeight),
                  _segmentModeRow(short: short),
                  Expanded(child: _setListGrid(narrow: narrow, short: short)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The room's name gives way first when the screen is narrow: on a
              // phone the countdown and the elapsed pair have to stay whole,
              // and a comedian already knows which room they are in.
              Flexible(
                child: Row(
                  key: StageRegion.venue.key,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.isRecording) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Palette.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        state.venue.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.6,
                          color: Palette.dim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Not flexible: the clocks are the part that must stay whole, so
              // the room's name is the only thing that yields.
              Row(
                key: StageRegion.clocks.key,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    countdown(state.remaining),
                    style: TextStyle(
                      fontFamily: Typeface.mono,
                      fontSize: 28,
                      color: _countdownColour,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${clock(state.elapsed)} / ${clock(state.model.plannedLength)}',
                    style: const TextStyle(
                      fontFamily: Typeface.mono,
                      fontSize: 14,
                      color: Palette.mute,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _pacingBar(),
        ],
      ),
    );
  }

  Color get _countdownColour => switch (Countdown.tone(state.remaining)) {
        CountdownTone.neutral => Palette.bone,
        CountdownTone.warning => Palette.orange,
        CountdownTone.over => Palette.red,
      };

  /// One segment per joke, sized by its estimate: the set's shape, and where in
  /// it the comedian actually is.
  Widget _pacingBar() {
    return SizedBox(
      key: StageRegion.pacingBar.key,
      height: 7,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = state.model.cards;
          // A joke with no estimate still has to occupy the bar, or the set's
          // shape would silently omit it. Two minutes is the drawing's stand-in
          // and nothing else reads it — the planned-length rule in the core
          // keeps treating an unestimated joke as contributing nothing.
          double weightOf(StageCard card) =>
              (card.joke.estimatedLength ?? const Duration(seconds: 120)).inMicroseconds / 1e6;
          final sum = cards.fold<double>(0, (total, card) => total + weightOf(card));
          if (sum <= 0) return const SizedBox.shrink();
          final gaps = (cards.length - 1).clamp(0, cards.length) * 3.0;
          final available = (constraints.maxWidth - gaps).clamp(0.0, double.infinity);
          return Row(
            // Stretch, so each segment takes the bar's full height: a box with
            // only a width and a colour has no height of its own, and the bar
            // renders as nothing at all.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                SizedBox(
                  width: available * weightOf(cards[i]) / sum,
                  child: ColoredBox(color: _paceColour(cards[i].state)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Color _paceColour(CardState state) => switch (state) {
        CardState.told => Palette.green,
        CardState.live => Palette.orange,
        CardState.queued => Palette.rule,
      };

  // ---------------------------------------------------------- current joke

  static Widget _flexIf(bool flex, Widget child) =>
      flex ? Flexible(child: child) : child;

  /// The share of the screen the joke panel may take before the set list
  /// starts losing cards it cannot afford to lose.
  ///
  /// Only applied on a narrow screen. A phone cannot show the whole body *and*
  /// nine readable cards, so the body is what gives: a comedian mid-bit is
  /// reading the top of it, and the grid is what they navigate by.
  static const double cappedPanelShare = 0.34;

  /// The height below which the joke panel has to give the set list room.
  static const double shortHeight = 600;

  Widget _currentJoke({required bool capped, required double available}) {
    final card = state.liveCard;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: capped ? available * cappedPanelShare : double.infinity,
        ),
        child: Container(
        key: StageRegion.currentJoke.key,
        width: double.infinity,
        color: Palette.panel,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, width: 6,
                child: const ColoredBox(color: Palette.orange)),
            Padding(
              // A capped panel tightens its own rhythm before it gives up any
              // of its content: the title, the tags and the strip all still
              // have to be there, and only the space between them is spare.
              padding: EdgeInsets.symmetric(
                horizontal: 22,
                vertical: capped ? 10 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card != null) ...[
                    Row(
                      key: StageRegion.jokeTitleRow.key,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            card.joke.title,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                        Text(
                          'on ${clock(state.runTimeOf(card))}',
                          style: const TextStyle(
                            fontFamily: Typeface.mono,
                            fontSize: 16,
                            color: Palette.dim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Flexible only where there is a bound to flex within: on
                    // a wide screen the panel is unbounded, and a flex child in
                    // an unbounded column is a layout error rather than a
                    // shrink-wrap.
                    _flexIf(
                      capped,
                      Text.rich(
                        jokeBody(card.joke),
                        key: StageRegion.jokeBody.key,
                        overflow: capped ? TextOverflow.ellipsis : TextOverflow.clip,
                        style: const TextStyle(fontSize: 25, height: 1.36),
                      ),
                    ),
                    if (card.joke.tags.isNotEmpty || card.joke.callbacks.isNotEmpty) ...[
                      SizedBox(height: capped ? 8 : 14),
                      _tags(card.joke),
                    ],
                  ] else
                    Text(
                      'Tap a card to start',
                      key: StageRegion.jokeBody.key,
                      style: const TextStyle(fontSize: 25, color: Palette.dim),
                    ),
                  SizedBox(height: capped ? 8 : 14),
                  _laughStrip(),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// The joke's text with its crucial setups highlighted — the words the punch
  /// depends on, the ones a tired comic paraphrases away.
  ///
  /// The highlight is weight and the live colour, never a darker shade, which
  /// reads as de-emphasis. That is requirement 3.3's wording rather than a
  /// platform limit: unlike the SwiftUI original, a span here could carry a
  /// background, and the spec is what says it should not.
  static TextSpan jokeBody(Joke joke) {
    final characters = joke.body.split('');
    final marked = [
      for (final span in joke.setups)
        if (span.start >= 0 && span.length > 0 && span.start + span.length <= characters.length)
          span,
    ]..sort((a, b) => a.start.compareTo(b.start));

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final span in marked) {
      if (span.start < cursor) continue; // overlapping spans: first one wins
      if (span.start > cursor) {
        spans.add(TextSpan(
          text: characters.sublist(cursor, span.start).join(),
          style: const TextStyle(color: Palette.bone),
        ));
      }
      spans.add(TextSpan(
        text: characters.sublist(span.start, span.start + span.length).join(),
        style: const TextStyle(color: Palette.orange, fontWeight: FontWeight.w700),
      ));
      cursor = span.start + span.length;
    }
    if (cursor < characters.length) {
      spans.add(TextSpan(
        text: characters.sublist(cursor).join(),
        style: const TextStyle(color: Palette.bone),
      ));
    }
    return TextSpan(children: spans);
  }

  Widget _tags(Joke joke) {
    // Wraps rather than overflowing: the tags are the panel's least urgent
    // content, so on a narrow screen they take a second line instead of
    // pushing themselves off the edge.
    return Wrap(
      key: StageRegion.jokeTags.key,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final _ in joke.callbacks) _tag('callback', Palette.green),
        for (final text in joke.tags) _tag(text, Palette.dim),
      ],
    );
  }

  Widget _tag(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(fontSize: 15, color: accent)),
    );
  }

  /// One bar, lit while the room is louder than the comedian can talk over.
  /// The one thing genuinely hard to judge from behind a mic.
  Widget _laughStrip() {
    return Container(
      key: StageRegion.laughStrip.key,
      height: 10,
      width: double.infinity,
      color: state.laughLevel > StageState.speakOverThreshold ? Palette.green : Palette.rule,
    );
  }

  // ---------------------------------------------------------- segment mode

  Widget _segmentModeRow({required bool short}) {
    final on = state.model.segmentMode == SegmentMode.autodetect;
    return Padding(
      // A short screen buys the set list its last rows out of the spacing
      // between blocks before it takes anything out of the blocks themselves.
      padding: EdgeInsets.fromLTRB(16, short ? 6 : 16, 16, 0),
      child: Row(
        key: StageRegion.segmentMode.key,
        children: [
          Switch(
            value: on,
            onChanged: state.model.autodetectAvailable
                ? (value) => onSetSegmentMode?.call(
                    value ? SegmentMode.autodetect : SegmentMode.manual)
                : null,
          ),
          const SizedBox(width: 13),
          Text(
            on ? 'Autodetect bits' : 'Manual switch',
            style: TextStyle(fontSize: 17, color: on ? Palette.green : Palette.dim),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- set list

  Widget _setListGrid({required bool narrow, required bool short}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, short ? 6 : 14, 16, short ? 6 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The count and the key share a line where there is room and stack
          // where there is not. Both have to be on the screen — 4.4 and 4.3 —
          // and a narrow phone cannot hold them side by side.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 13,
            runSpacing: 6,
            children: [
              SizedBox(
                width: narrow ? double.infinity : null,
                child: Text(
                  'SET LIST · ${state.model.startedCount} / ${state.model.plannedCount}',
                  key: StageRegion.setListCount.key,
                  style: const TextStyle(fontSize: 14, letterSpacing: 0.6, color: Palette.dim),
                ),
              ),
              Row(
                key: StageRegion.setListKey.key,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _key('told', Palette.green),
                  const SizedBox(width: 13),
                  _key('live', Palette.orange),
                  const SizedBox(width: 13),
                  _key('queued', Palette.edge),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Rows rather than a scrolling grid: the set list takes whatever
          // height the joke panel leaves, so the cards fill one screen instead
          // of sizing to their text and stranding the bottom third.
          Expanded(
            child: Column(
              key: StageRegion.grid.key,
              children: [
                for (var r = 0; r < _rowsOf(narrow ? 2 : 3).length; r++) ...[
                  if (r > 0) const SizedBox(height: 9),
                  Expanded(
                    child: Row(
                      children: [
                        for (var c = 0; c < (narrow ? 2 : 3); c++) ...[
                          if (c > 0) const SizedBox(width: 9),
                          Expanded(
                            child: c < _rowsOf(narrow ? 2 : 3)[r].length
                                ? _cardFace(_rowsOf(narrow ? 2 : 3)[r][c])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The width below which the set list drops to two columns.
  ///
  /// Three cards across a phone leaves each about 120pt, which clips a title
  /// like "Flatmate rota" to five characters, and a card nobody can read is
  /// worse than a taller grid.
  static const double narrowWidth = 600;

  List<List<StageCard>> _rowsOf(int columns) {
    final cards = state.model.cards;
    return [
      for (var start = 0; start < cards.length; start += columns)
        cards.sublist(start, start + columns > cards.length ? cards.length : start + columns),
    ];
  }

  Widget _key(String label, Color colour) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: colour),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 13, color: Palette.dim)),
      ],
    );
  }

  /// A card carries its joke and how long it ran — never a laugh score
  /// (requirement 4.6).
  Widget _cardFace(StageCard card) {
    return GestureDetector(
      onTap: () => onTapCard?.call(card.id),
      child: Container(
        color: _cardBackground(card.state),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                card.joke.title,
                // Wraps and then ellipsises rather than cutting mid-word: a
                // title that reads "Flatmate" is a different bit from one that
                // reads "Flatmate rota", and the comedian is scanning for the
                // one they mean.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _cardTitleColour(card.state),
                ),
              ),
            ),
            Text(
              _cardFootnote(card),
              style: TextStyle(
                fontFamily: card.state == CardState.queued ? Typeface.sans : Typeface.mono,
                fontSize: 14,
                color: _cardFootnoteColour(card.state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cardFootnote(StageCard card) => switch (card.state) {
        CardState.live => 'LIVE · ${clock(state.runTimeOf(card))}',
        CardState.told => clock(state.runTimeOf(card)),
        CardState.queued => card.joke.estimatedLength == null
            ? '—'
            : '~${clock(card.joke.estimatedLength!)}',
      };

  static Color _cardBackground(CardState state) => switch (state) {
        CardState.told => Palette.greenDeep,
        CardState.live => Palette.orange,
        CardState.queued => Palette.panel,
      };

  static Color _cardTitleColour(CardState state) => switch (state) {
        CardState.told => Palette.green,
        CardState.live => Palette.ink,
        CardState.queued => Palette.bone,
      };

  static Color _cardFootnoteColour(CardState state) => switch (state) {
        CardState.told => Palette.greenInk,
        CardState.live => Palette.orangeDeep,
        CardState.queued => Palette.dim,
      };
}
