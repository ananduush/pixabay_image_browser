import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/favorites/services/favorites_storage_exception.dart';
import 'package:pixabay_image_browser/features/favorites/services/favorites_storage_service.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/pixabay_fixtures.dart';

class _MockPreferences extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPreferences preferences;
  late FavoritesStorageService service;

  const userId = 'user-a';
  final key = FavoritesStorageService.keyFor(userId);

  PixabayImage imageWith(int id) => PixabayImage.fromJson(sampleHit(id: id));

  setUp(() {
    preferences = _MockPreferences();
    service = FavoritesStorageService(preferences: preferences);
  });

  test('namespaces the key by user id', () {
    expect(key, 'favorites.user-a');
    expect(FavoritesStorageService.keyFor('user-b'), isNot(key));
  });

  test('a missing key reads as no favourites', () async {
    when(() => preferences.getString(key)).thenAnswer((_) async => null);

    expect(await service.read(userId), isEmpty);
  });

  test('write encodes Pixabay-shaped JSON that read parses back', () async {
    when(() => preferences.setString(key, any())).thenAnswer((_) async {});
    final images = <PixabayImage>[imageWith(1), imageWith(2)];

    await service.write(userId, images);

    final raw =
        verify(() => preferences.setString(key, captureAny())).captured.single
            as String;
    expect(jsonDecode(raw), isA<List<dynamic>>());
    when(() => preferences.getString(key)).thenAnswer((_) async => raw);
    final restored = await service.read(userId);
    expect(restored.map((i) => i.id), <int>[1, 2]);
    expect(restored.first.tags, images.first.tags);
    expect(restored.first.largeImageUrl, images.first.largeImageUrl);
  });

  final corrupt = throwsA(
    isA<FavoritesStorageException>().having(
      (e) => e.operation,
      'operation',
      FavoritesStorageOperation.decode,
    ),
  );

  group('decode', () {
    test('drops rows with an unusable id or a repeated id', () {
      final raw = jsonEncode(<Object?>[
        <String, dynamic>{'id': 0},
        <String, dynamic>{'id': -1},
        sampleHit(id: 7),
        sampleHit(id: 7),
        sampleHit(id: 8),
      ]);

      expect(FavoritesStorageService.decode(raw).map((i) => i.id), <int>[7, 8]);
    });

    group('a corrupt store throws a decode exception', () {
      test('when the value is not JSON', () {
        expect(() => FavoritesStorageService.decode('not json'), corrupt);
      });

      test('when the root is not a list', () {
        expect(() => FavoritesStorageService.decode('{"id": 1}'), corrupt);
      });

      test('when an entry is not an object', () {
        for (final entry in <Object?>[1, 'text', null]) {
          final raw = jsonEncode(<Object?>[sampleHit(id: 7), entry]);
          expect(() => FavoritesStorageService.decode(raw), corrupt);
        }
      });
    });
  });

  test('a corrupt value surfaces through read as a decode exception', () {
    when(() => preferences.getString(key)).thenAnswer((_) async => 'not json');

    expect(() => service.read(userId), corrupt);
  });

  test('a refused read surfaces as a read exception', () {
    when(() => preferences.getString(key)).thenThrow(StateError('no disk'));

    expect(
      () => service.read(userId),
      throwsA(
        isA<FavoritesStorageException>().having(
          (e) => e.operation,
          'operation',
          FavoritesStorageOperation.read,
        ),
      ),
    );
  });

  test('a refused write surfaces as a write exception', () {
    when(
      () => preferences.setString(key, any()),
    ).thenThrow(StateError('disk full'));

    expect(
      () => service.write(userId, <PixabayImage>[imageWith(1)]),
      throwsA(
        isA<FavoritesStorageException>().having(
          (e) => e.operation,
          'operation',
          FavoritesStorageOperation.write,
        ),
      ),
    );
  });
}
