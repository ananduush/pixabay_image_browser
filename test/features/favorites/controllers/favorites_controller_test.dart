import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_controller.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_state.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/favorites/controllers/favorites_controller.dart';
import 'package:pixabay_image_browser/features/favorites/controllers/favorites_state.dart';
import 'package:pixabay_image_browser/features/favorites/repositories/favorites_repository.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';

import '../../../support/auth_fixtures.dart';
import '../../../support/favorites_fixtures.dart';
import '../../../support/pixabay_fixtures.dart';

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

void main() {
  late StreamController<AuthUser?> changes;
  late AuthController auth;
  late FakeFavoritesStorageService storage;

  final userA = sampleUser(id: 'user-a', email: 'a@aperture.app');
  final userB = sampleUser(id: 'user-b', email: 'b@aperture.app');

  PixabayImage imageWith(int id) => PixabayImage.fromJson(sampleHit(id: id));
  List<int> ids(Iterable<PixabayImage> images) =>
      images.map((image) => image.id).toList();

  /// Lets every queued microtask and the storage futures run.
  Future<void> settle() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    changes = StreamController<AuthUser?>.broadcast();
    storage = FakeFavoritesStorageService();
  });

  tearDown(() => changes.close());

  AuthController signedIn(AuthUser? user) {
    auth = AuthController(
      repository: stubAuthRepository(
        MockAuthRepository(),
        user: user,
        changes: changes,
      ),
    )..onInit();
    addTearDown(auth.onClose);
    return auth;
  }

  FavoritesController start(AuthUser? user, {FavoritesRepository? repository}) {
    final controller = FavoritesController(
      auth: signedIn(user),
      repository: repository ?? FavoritesRepository(storage: storage),
    )..onInit();
    addTearDown(controller.onClose);
    return controller;
  }

  Future<void> switchUser(AuthUser? user) async {
    changes.add(user);
    await settle();
  }

  test('a guest has no active favourites and never touches storage', () async {
    final controller = start(null);
    await settle();

    expect(controller.state.value, const FavoritesInactive());
    expect(controller.count, isNull);
    expect(controller.isFavorite(1), isFalse);
    expect(storage.reads, 0);

    expect(await controller.toggle(imageWith(1)), isFalse);
    expect(storage.writes, 0);
  });

  test('a signed-in user gets their persisted favourites loaded', () async {
    storage.seed(userA.id, <PixabayImage>[imageWith(1), imageWith(2)]);
    final controller = start(userA);

    expect(controller.state.value, FavoritesLoading(userA.id));
    await settle();

    expect(
      controller.state.value,
      isA<FavoritesLoaded>().having((s) => s.userId, 'userId', userA.id).having(
        (s) => ids(s.images),
        'ids',
        <int>[1, 2],
      ),
    );
    expect(controller.count, 2);
    expect(controller.isFavorite(2), isTrue);
    expect(controller.isFavorite(3), isFalse);
  });

  test('auth transitions swap namespaces without deleting anything', () async {
    storage.seed(userA.id, <PixabayImage>[imageWith(1)]);
    storage.seed(userB.id, <PixabayImage>[imageWith(2)]);
    final controller = start(userA);
    await settle();
    expect(ids((controller.state.value as FavoritesLoaded).images), <int>[1]);

    await switchUser(null);
    expect(controller.state.value, const FavoritesInactive());
    expect(ids(storage.saved(userA.id)), <int>[1]);

    await switchUser(userB);
    expect(
      controller.state.value,
      isA<FavoritesLoaded>().having((s) => s.userId, 'userId', userB.id).having(
        (s) => ids(s.images),
        'ids',
        <int>[2],
      ),
    );

    await switchUser(null);
    await switchUser(userA);
    expect(
      controller.state.value,
      isA<FavoritesLoaded>().having((s) => s.userId, 'userId', userA.id).having(
        (s) => ids(s.images),
        'ids',
        <int>[1],
      ),
    );
  });

  test('the signing-out flag and repeated auth events do not reload', () async {
    final controller = start(userA);
    await settle();
    final readsAfterLoad = storage.reads;

    auth.state.value = AuthAuthenticated(userA, signingOut: true);
    await settle();
    changes.add(userA);
    await settle();

    expect(storage.reads, readsAfterLoad);
    expect(controller.state.value, isA<FavoritesLoaded>());
  });

  test('toggle adds then removes, persisting each step', () async {
    final controller = start(userA);
    await settle();
    final image = imageWith(5);

    expect(await controller.toggle(image), isTrue);
    expect(controller.isFavorite(5), isTrue);
    expect(ids(storage.saved(userA.id)), <int>[5]);

    expect(await controller.toggle(image), isTrue);
    expect(controller.isFavorite(5), isFalse);
    expect(storage.saved(userA.id), isEmpty);
    expect(controller.state.value, FavoritesLoaded(userA.id, const []));
  });

  test('adding twice keeps a single copy', () async {
    final controller = start(userA);
    await settle();
    final image = imageWith(5);

    await controller.add(image);
    await controller.add(image);

    expect(controller.count, 1);
    expect(storage.saved(userA.id), hasLength(1));
  });

  test('rapid taps leave storage matching the final state', () async {
    final controller = start(userA);
    await settle();
    final image = imageWith(5);

    final taps = <Future<bool>>[
      for (var i = 0; i < 5; i++) controller.toggle(image),
    ];
    // the pill already shows the outcome of the last tap
    expect(controller.isFavorite(5), isTrue);
    expect(await Future.wait(taps), everyElement(isTrue));
    await settle();

    expect(controller.isFavorite(5), isTrue);
    expect(ids(storage.saved(userA.id)), <int>[5]);

    for (var i = 0; i < 4; i++) {
      unawaited(controller.toggle(image));
    }
    expect(controller.isFavorite(5), isTrue);
    await settle();
    expect(controller.isFavorite(5), isTrue);
    expect(ids(storage.saved(userA.id)), <int>[5]);

    unawaited(controller.toggle(image));
    await settle();
    expect(controller.isFavorite(5), isFalse);
    expect(storage.saved(userA.id), isEmpty);
  });

  test(
    'a write finishing after a user switch stays in its own namespace',
    () async {
      final repository = _MockFavoritesRepository();
      final image = imageWith(5);
      when(() => repository.load(userA.id)).thenAnswer((_) async => const []);
      when(() => repository.load(userB.id)).thenAnswer((_) async => const []);
      final pendingAdd = Completer<List<PixabayImage>>();
      when(
        () => repository.add(userA.id, image),
      ).thenAnswer((_) => pendingAdd.future);
      final controller = start(userA, repository: repository);
      await settle();

      final adding = controller.add(image);
      expect(controller.isFavorite(5), isTrue);

      await switchUser(userB);
      // B's load is queued behind A's write
      expect(controller.state.value, FavoritesLoading(userB.id));

      pendingAdd.complete(<PixabayImage>[image]);
      expect(await adding, isTrue);
      await settle();

      expect(controller.state.value, FavoritesLoaded(userB.id, const []));
      expect(controller.isFavorite(5), isFalse);
      verify(() => repository.add(userA.id, image)).called(1);
      verifyNever(() => repository.add(userB.id, image));
    },
  );

  test('a load failure is reported and Retry recovers', () async {
    storage
      ..seed(userA.id, <PixabayImage>[imageWith(1)])
      ..failReads = true;
    final controller = start(userA);
    await settle();

    expect(
      controller.state.value,
      isA<FavoritesLoadFailed>().having((s) => s.userId, 'userId', userA.id),
    );
    expect(controller.count, isNull);

    storage.failReads = false;
    await controller.retryLoad();
    await settle();

    expect(
      controller.state.value,
      isA<FavoritesLoaded>().having((s) => ids(s.images), 'ids', <int>[1]),
    );
  });

  test('a failed add rolls back and reports false', () async {
    final controller = start(userA);
    await settle();
    storage.failWrites = true;
    final image = imageWith(5);

    final result = controller.add(image);
    expect(controller.isFavorite(5), isTrue);

    expect(await result, isFalse);
    await settle();
    expect(controller.isFavorite(5), isFalse);
    expect(controller.state.value, FavoritesLoaded(userA.id, const []));
    expect(storage.saved(userA.id), isEmpty);
  });

  test('a failed remove keeps the favourite and reports false', () async {
    storage.seed(userA.id, <PixabayImage>[imageWith(1)]);
    final controller = start(userA);
    await settle();
    storage.failWrites = true;

    final result = controller.remove(1);
    expect(controller.isFavorite(1), isFalse);

    expect(await result, isFalse);
    await settle();
    expect(controller.isFavorite(1), isTrue);
    expect(ids(storage.saved(userA.id)), <int>[1]);
  });

  test('a save attempted while the list is unreadable fails cleanly', () async {
    storage.failReads = true;
    final controller = start(userA);
    await settle();
    expect(controller.state.value, isA<FavoritesLoadFailed>());

    expect(await controller.add(imageWith(1)), isFalse);
    expect(controller.state.value, isA<FavoritesLoadFailed>());
    expect(storage.writes, 0);
  });

  test('states compare by value so equal sets are dropped', () {
    final one = FavoritesLoaded('u', <PixabayImage>[imageWith(1)]);
    final same = FavoritesLoaded('u', <PixabayImage>[imageWith(1)]);
    final other = FavoritesLoaded('u', <PixabayImage>[imageWith(2)]);

    expect(one, same);
    expect(one.hashCode, same.hashCode);
    expect(one, isNot(other));
    expect(one, isNot(FavoritesLoaded('v', <PixabayImage>[imageWith(1)])));
    expect(const FavoritesInactive(), const FavoritesInactive());
    expect(FavoritesLoading('u'), FavoritesLoading('u'));
  });
}
