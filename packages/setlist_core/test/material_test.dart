import 'dart:convert';
import 'dart:io';

import 'package:setlist_core/setlist_core.dart';
import 'package:test/test.dart';

void main() {
  test('1.1 a joke carries the fields the product reuses it by', () {
    final joke = Joke(
      title: 'Airport security',
      body: 'They asked me to remove my shoes.',
      setups: const [SetupSpan(start: 5, length: 6)],
      notes: const ['slow the tag'],
      tags: const ['travel'],
      callbacks: const ['van'],
      estimatedLength: const Duration(seconds: 150),
    );

    expect(joke.title, 'Airport security');
    expect(joke.tags, ['travel']);
    expect(joke.callbacks, ['van']);
    expect(joke.estimatedLength, const Duration(seconds: 150));
  });

  test('1.1 an unestimated joke has no length, not a zero one', () {
    // A zero would claim the joke takes no time, which the set's planned length
    // would then believe.
    expect(Joke(title: 'New bit', body: '...').estimatedLength, isNull);
  });

  group('1.2 setup spans', () {
    test('survive an encode/decode round trip with their offsets intact', () {
      final joke = Joke(
        id: 'j1',
        title: 'Airport security',
        body: 'They asked me to remove my shoes.',
        setups: const [SetupSpan(start: 5, length: 6)],
      );
      expect(joke.setupText(joke.setups.first), 'asked ');

      final back = Joke.fromJson(json.decode(json.encode(joke.toJson())) as Map<String, dynamic>);

      expect(back.setups, joke.setups);
      expect(back.setupText(back.setups.first), 'asked ');
    });

    test('report no text when the span falls outside the body', () {
      final joke = Joke(title: 'Short', body: 'Hi');
      expect(joke.setupText(const SetupSpan(start: 1, length: 99)), isNull);
    });
  });

  test('1.3 reordering a set changes positions only, never identity', () {
    final set = SetList(name: 'Fri late', jokeIds: ['a', 'b', 'c']);

    set.move(from: 2, to: 0);

    expect(set.jokeIds, ['c', 'a', 'b']);
    expect(set.jokeIds.toSet(), {'a', 'b', 'c'});
  });

  group("1.4 a set's planned length", () {
    test("is the sum of its jokes' estimates", () {
      final library = Library(
        jokes: [
          Joke(id: 'a', title: 'A', body: '', estimatedLength: const Duration(seconds: 90)),
          Joke(id: 'b', title: 'B', body: '', estimatedLength: const Duration(seconds: 150)),
        ],
        sets: [SetList(id: 's', name: 'Set', jokeIds: ['a', 'b'])],
      );

      expect(library.plannedLength(library.sets.first), const Duration(seconds: 240));
    });

    test('counts an unestimated joke as nothing rather than guessing', () {
      final library = Library(
        jokes: [
          Joke(id: 'a', title: 'A', body: '', estimatedLength: const Duration(seconds: 90)),
          Joke(id: 'b', title: 'B', body: ''),
        ],
        sets: [SetList(id: 's', name: 'Set', jokeIds: ['a', 'b'])],
      );

      expect(library.plannedLength(library.sets.first), const Duration(seconds: 90));
    });

    test('drops an id with no joke behind it rather than faking a card', () {
      final library = Library(
        jokes: [Joke(id: 'a', title: 'A', body: '')],
        sets: [SetList(id: 's', name: 'Set', jokeIds: ['a', 'deleted'])],
      );

      expect(library.jokesOf(library.sets.first).map((j) => j.id), ['a']);
    });
  });

  group('1.5 audience descriptors', () {
    test('are each independently unknown', () {
      const audience = Audience(seating: Seating.seated);

      expect(audience.size, isNull);
      expect(audience.seating, Seating.seated);
      expect(audience.service, isNull);
      expect(audience.crowd, isNull);
    });

    test('keep an unknown size distinct from an empty room', () {
      // "unknown size, seated" and "0 people, seated" are different facts, and
      // the analysis product would draw different conclusions from them.
      const unknown = Audience(seating: Seating.seated);
      const empty = Audience(size: 0, seating: Seating.seated);

      expect(unknown, isNot(equals(empty)));
      expect(unknown.toJson().containsKey('size'), isFalse);
      expect(empty.toJson()['size'], 0);
    });

    test('survive a round trip without an absent one becoming a default', () {
      const audience = Audience(size: 80, crowd: Crowd.publicRoom);
      final back = Audience.fromJson(
        json.decode(json.encode(audience.toJson())) as Map<String, dynamic>,
      );

      expect(back, audience);
      expect(back.seating, isNull);
      expect(back.service, isNull);
    });

    test('decode an unrecognised value as unknown rather than the first option', () {
      // A file written by a later version must not become confidently wrong
      // data when an older build reads it.
      final back = Audience.fromJson(const {'seating': 'hammocks'});
      expect(back.seating, isNull);
    });
  });

  test('1.6 the library survives relaunch', () async {
    final dir = await Directory.systemTemp.createTemp('setlist-library');
    addTearDown(() => dir.delete(recursive: true));
    final store = FileLibraryStore.inContainer(dir);

    final written = Library(
      jokes: [
        Joke(id: 'j', title: 'Airport security', body: 'Shoes off.',
            estimatedLength: const Duration(seconds: 150)),
      ],
      sets: [SetList(id: 's', name: 'Fri late', jokeIds: ['j'])],
      shows: [
        Show(
          id: 'sh',
          venue: 'The Stand',
          startedAt: DateTime.utc(2026, 8, 21, 22, 30),
          plannedLength: const Duration(minutes: 20),
          audience: const Audience(size: 80, seating: Seating.seated),
        ),
      ],
    );
    await store.save(written);

    // A second store over the same file is the next launch.
    final read = await FileLibraryStore.inContainer(dir).load();

    expect(read.jokes.single.title, 'Airport security');
    expect(read.jokes.single.estimatedLength, const Duration(seconds: 150));
    expect(read.sets.single.jokeIds, ['j']);
    expect(read.shows.single.venue, 'The Stand');
    expect(read.shows.single.startedAt, DateTime.utc(2026, 8, 21, 22, 30));
    expect(read.shows.single.audience.size, 80);
  });

  test('1.6 a library that was never written reads back empty, not missing', () async {
    final dir = await Directory.systemTemp.createTemp('setlist-empty');
    addTearDown(() => dir.delete(recursive: true));

    final read = await FileLibraryStore.inContainer(dir).load();

    expect(read.jokes, isEmpty);
    expect(read.sets, isEmpty);
  });
}
