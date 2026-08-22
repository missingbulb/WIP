import 'ids.dart';

/// A span of a joke's body the comedian must not paraphrase — the stage screen
/// highlights these. Offsets are into `body`'s character view.
class SetupSpan {
  const SetupSpan({required this.start, required this.length});

  final int start;
  final int length;

  Map<String, dynamic> toJson() => {'start': start, 'length': length};

  factory SetupSpan.fromJson(Map<String, dynamic> json) =>
      SetupSpan(start: json['start'] as int, length: json['length'] as int);

  @override
  bool operator ==(Object other) =>
      other is SetupSpan && other.start == start && other.length == length;

  @override
  int get hashCode => Object.hash(start, length);
}

/// A durable unit of material. The joke is what a comedian owns and reuses;
/// everything else in the model points at one.
class Joke {
  Joke({
    String? id,
    required this.title,
    required this.body,
    this.setups = const [],
    this.notes = const [],
    this.tags = const [],
    this.callbacks = const [],
    this.estimatedLength,
  }) : id = id ?? newId();

  final String id;
  final String title;
  final String body;

  /// Spans of [body] carrying the setup the punch depends on.
  final List<SetupSpan> setups;

  /// Alternate tags, delivery notes — the optional text an expanded card shows.
  final List<String> notes;
  final List<String> tags;

  /// Jokes this one calls back to.
  final List<String> callbacks;

  /// The comedian's own estimate, in seconds. Unknown stays absent — never a
  /// zero, which would be a claim that the joke takes no time.
  final Duration? estimatedLength;

  /// The text a setup span covers, or null when the span falls outside [body].
  String? setupText(SetupSpan span) {
    final characters = body.split('');
    if (span.start < 0 || span.length < 0 || span.start + span.length > characters.length) {
      return null;
    }
    return characters.sublist(span.start, span.start + span.length).join();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'setups': [for (final s in setups) s.toJson()],
        'notes': notes,
        'tags': tags,
        'callbacks': callbacks,
        // Absent stays absent through the round trip.
        if (estimatedLength != null) 'estimatedLengthSeconds': estimatedLength!.inMilliseconds / 1000,
      };

  factory Joke.fromJson(Map<String, dynamic> json) => Joke(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        setups: [
          for (final s in (json['setups'] as List<dynamic>? ?? []))
            SetupSpan.fromJson(s as Map<String, dynamic>),
        ],
        notes: [...?(json['notes'] as List<dynamic>?)?.cast<String>()],
        tags: [...?(json['tags'] as List<dynamic>?)?.cast<String>()],
        callbacks: [...?(json['callbacks'] as List<dynamic>?)?.cast<String>()],
        estimatedLength: json.containsKey('estimatedLengthSeconds')
            ? Duration(milliseconds: ((json['estimatedLengthSeconds'] as num) * 1000).round())
            : null,
      );
}

/// An ordered list of jokes planned for a show. Named [SetList] because a set
/// is also a collection type.
///
/// It holds ids rather than copies: a joke edited in the library is edited
/// everywhere it is planned.
class SetList {
  SetList({String? id, required this.name, List<String>? jokeIds})
      : id = id ?? newId(),
        jokeIds = jokeIds ?? [];

  final String id;
  final String name;

  /// Jokes in performance order. Order is position only — never identity.
  final List<String> jokeIds;

  void move({required int from, required int to}) {
    if (from < 0 || from >= jokeIds.length || to < 0 || to >= jokeIds.length) return;
    final jokeId = jokeIds.removeAt(from);
    jokeIds.insert(to, jokeId);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'jokeIds': jokeIds};

  factory SetList.fromJson(Map<String, dynamic> json) => SetList(
        id: json['id'] as String,
        name: json['name'] as String,
        jokeIds: [...?(json['jokeIds'] as List<dynamic>?)?.cast<String>()],
      );
}

enum Seating { seated, standing, mixed }

enum Service { none, drinks, dinner }

enum Crowd { publicRoom, corporate, comics, students, privateEvent }

/// What the room was.
///
/// Every descriptor is independently unknown: an unset one is absent, never a
/// zero or an empty string, so "unknown size, seated" and "0 people, seated"
/// stay different facts.
class Audience {
  const Audience({this.size, this.seating, this.service, this.crowd, this.note});

  final int? size;
  final Seating? seating;
  final Service? service;
  final Crowd? crowd;

  /// Whatever the structured fields cannot hold.
  final String? note;

  Map<String, dynamic> toJson() => {
        if (size != null) 'size': size,
        if (seating != null) 'seating': seating!.name,
        if (service != null) 'service': service!.name,
        if (crowd != null) 'crowd': crowd!.name,
        if (note != null) 'note': note,
      };

  factory Audience.fromJson(Map<String, dynamic> json) => Audience(
        size: json['size'] as int?,
        seating: _byName(Seating.values, json['seating'] as String?),
        service: _byName(Service.values, json['service'] as String?),
        crowd: _byName(Crowd.values, json['crowd'] as String?),
        note: json['note'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is Audience &&
      other.size == size &&
      other.seating == seating &&
      other.service == service &&
      other.crowd == crowd &&
      other.note == note;

  @override
  int get hashCode => Object.hash(size, seating, service, crowd, note);
}

T? _byName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  // An unrecognised value is unknown, not the first of the list: a decoder that
  // guesses turns a newer file into confidently wrong data.
  return null;
}

/// One performance event, with one recording.
class Show {
  Show({
    String? id,
    required this.venue,
    required this.startedAt,
    required this.plannedLength,
    this.audience = const Audience(),
    this.setListId,
  }) : id = id ?? newId();

  final String id;
  final String venue;
  final DateTime startedAt;

  /// The slot the comedian was given.
  final Duration plannedLength;
  final Audience audience;
  final String? setListId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'venue': venue,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'plannedLengthSeconds': plannedLength.inMilliseconds / 1000,
        'audience': audience.toJson(),
        if (setListId != null) 'setListId': setListId,
      };

  factory Show.fromJson(Map<String, dynamic> json) => Show(
        id: json['id'] as String,
        venue: json['venue'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        plannedLength:
            Duration(milliseconds: ((json['plannedLengthSeconds'] as num) * 1000).round()),
        audience: Audience.fromJson((json['audience'] as Map<String, dynamic>?) ?? const {}),
        setListId: json['setListId'] as String?,
      );
}

/// Everything the comedian owns, and the one thing that resolves a set's ids
/// back into jokes.
class Library {
  Library({List<Joke>? jokes, List<SetList>? sets, List<Show>? shows})
      : jokes = jokes ?? [],
        sets = sets ?? [],
        shows = shows ?? [];

  final List<Joke> jokes;
  final List<SetList> sets;
  final List<Show> shows;

  Joke? joke(String id) {
    for (final joke in jokes) {
      if (joke.id == id) return joke;
    }
    return null;
  }

  /// The set's jokes, in order.
  ///
  /// An id with no joke behind it is dropped rather than faked — a deleted joke
  /// leaves a shorter set, not a blank card on stage.
  List<Joke> jokesOf(SetList set) => [
        for (final id in set.jokeIds)
          if (joke(id) case final Joke found) found,
      ];

  /// The planned length of a set: its jokes' estimates summed. A joke with no
  /// estimate contributes nothing rather than a guess.
  Duration plannedLength(SetList set) {
    var total = Duration.zero;
    for (final joke in jokesOf(set)) {
      total += joke.estimatedLength ?? Duration.zero;
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'jokes': [for (final j in jokes) j.toJson()],
        'sets': [for (final s in sets) s.toJson()],
        'shows': [for (final s in shows) s.toJson()],
      };

  factory Library.fromJson(Map<String, dynamic> json) => Library(
        jokes: [
          for (final j in (json['jokes'] as List<dynamic>? ?? []))
            Joke.fromJson(j as Map<String, dynamic>),
        ],
        sets: [
          for (final s in (json['sets'] as List<dynamic>? ?? []))
            SetList.fromJson(s as Map<String, dynamic>),
        ],
        shows: [
          for (final s in (json['shows'] as List<dynamic>? ?? []))
            Show.fromJson(s as Map<String, dynamic>),
        ],
      );
}
