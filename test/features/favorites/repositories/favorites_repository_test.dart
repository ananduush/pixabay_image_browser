import 'package:flutter_test/flutter_test.dart';
import 'package:pixabay_image_browser/features/favorites/repositories/favorites_repository.dart';
import 'package:pixabay_image_browser/features/favorites/services/favorites_storage_exception.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';

import '../../../support/favorites_fixtures.dart';
import '../../../support/pixabay_fixtures.dart';

void main() {
  late FakeFavoritesStorageService storage;
  late FavoritesRepository repository;

  const userA = 'user-a';
  const userB = 'user-b';

  PixabayImage imageWith(int id) => PixabayImage.fromJson(sampleHit(id: id));

  setUp(() {
    storage = FakeFavoritesStorageService();
    repository = FavoritesRepository(storage: storage);
  });

  test('add persists the image for that user', () async {
    final result = await repository.add(userA, imageWith(1));

    expect(result.map((i) => i.id), <int>[1]);
    expect(storage.saved(userA).map((i) => i.id), <int>[1]);
    expect(await repository.load(userA), result);
  });

  test('remove persists the shorter list', () async {
    await repository.add(userA, imageWith(1));
    await repository.add(userA, imageWith(2));

    final result = await repository.remove(userA, 1);

    expect(result.map((i) => i.id), <int>[2]);
    expect(storage.saved(userA).map((i) => i.id), <int>[2]);
  });

  test('adding the same image twice stores exactly one copy', () async {
    await repository.add(userA, imageWith(1));
    final result = await repository.add(userA, imageWith(1));

    expect(result.map((i) => i.id), <int>[1]);
    expect(storage.saved(userA), hasLength(1));
    // the second add saw the duplicate and did not touch the disk
    expect(storage.writes, 1);
  });

  test('removing an absent id does not write', () async {
    await repository.add(userA, imageWith(1));

    final result = await repository.remove(userA, 99);

    expect(result.map((i) => i.id), <int>[1]);
    expect(storage.writes, 1);
  });

  test('users on one device never see each other\'s favourites', () async {
    await repository.add(userA, imageWith(1));
    await repository.add(userB, imageWith(2));

    expect((await repository.load(userA)).map((i) => i.id), <int>[1]);
    expect((await repository.load(userB)).map((i) => i.id), <int>[2]);

    await repository.remove(userB, 2);
    expect((await repository.load(userA)).map((i) => i.id), <int>[1]);
    expect(await repository.load(userB), isEmpty);
  });

  test('a new repository over the same storage restores the list', () async {
    await repository.add(userA, imageWith(1));

    final restored = await FavoritesRepository(storage: storage).load(userA);

    expect(restored.map((i) => i.id), <int>[1]);
  });

  test('storage errors propagate untouched', () async {
    storage.failReads = true;
    expect(
      () => repository.load(userA),
      throwsA(isA<FavoritesStorageException>()),
    );
    expect(
      () => repository.add(userA, imageWith(1)),
      throwsA(isA<FavoritesStorageException>()),
    );

    storage.failReads = false;
    storage.failWrites = true;
    expect(
      () => repository.add(userA, imageWith(1)),
      throwsA(isA<FavoritesStorageException>()),
    );
    expect(storage.saved(userA), isEmpty);
  });
}
