import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/auth_state.dart';
import '../../gallery/models/pixabay_image.dart';
import '../repositories/favorites_repository.dart';
import '../services/favorites_storage_exception.dart';
import 'favorites_state.dart';

/// The signed-in user's favourites, kept in step with [AuthController].
///
/// Every storage operation runs through one ordered queue, so read-modify-
/// write cycles never interleave and a load for a newly signed-in user runs
/// after any write still in flight. Each operation captures the user id and
/// a generation counter when it is enqueued: writes always target the
/// captured user's namespace, and a completion whose generation is stale
/// never touches the state of whoever is signed in now.
class FavoritesController extends GetxController {
  FavoritesController({required this._auth, required this._repository});

  final AuthController _auth;
  final FavoritesRepository _repository;

  final Rx<FavoritesState> state = Rx<FavoritesState>(
    const FavoritesInactive(),
  );

  StreamSubscription<AuthState>? _authSubscription;
  String? _userId;
  int _generation = 0;

  /// Mutations enqueued but not yet completed. A completing operation only
  /// publishes its result when it is the last one, so the optimistic state
  /// never flickers back while later taps are still queued.
  int _pending = 0;

  Future<void> _queue = Future<void>.value();

  @override
  void onInit() {
    super.onInit();
    // Subscribe before reading: Rx streams do not replay.
    _authSubscription = _auth.state.listen(_onAuthChanged);
    _onAuthChanged(_auth.state.value);
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  /// Reads `state.value` on every path so an [Obx] around it always tracks.
  bool isFavorite(int id) => state.value.contains(id);

  /// Saved count, or null until the current user's list has loaded.
  int? get count => switch (state.value) {
    FavoritesLoaded(:final images) => images.length,
    FavoritesInactive() || FavoritesLoading() || FavoritesLoadFailed() => null,
  };

  Future<void> retryLoad() {
    final userId = _userId;
    if (userId == null) return Future<void>.value();
    return _load(userId, _generation);
  }

  /// Saves or removes [image]; false only when persistence failed.
  Future<bool> toggle(PixabayImage image) =>
      isFavorite(image.id) ? remove(image.id) : add(image);

  Future<bool> add(PixabayImage image) {
    return _mutate(
      optimistic: (List<PixabayImage> images) =>
          images.any((saved) => saved.id == image.id)
          ? images
          : <PixabayImage>[...images, image],
      persist: (String userId) => _repository.add(userId, image),
    );
  }

  Future<bool> remove(int id) {
    return _mutate(
      optimistic: (List<PixabayImage> images) =>
          images.where((saved) => saved.id != id).toList(growable: false),
      persist: (String userId) => _repository.remove(userId, id),
    );
  }

  void _onAuthChanged(AuthState auth) {
    final userId = auth.user?.id;
    // Same account (e.g. signing-out flag, token refresh): nothing to do.
    if (userId == _userId) return;
    _userId = userId;
    _generation++;
    if (userId == null) {
      state.value = const FavoritesInactive();
      return;
    }
    unawaited(_load(userId, _generation));
  }

  Future<void> _load(String userId, int generation) {
    state.value = FavoritesLoading(userId);
    return _enqueue(() async {
      if (generation != _generation) return;
      try {
        final images = await _repository.load(userId);
        if (generation != _generation || _pending > 0) return;
        state.value = FavoritesLoaded(userId, images);
      } catch (error) {
        if (generation == _generation) {
          state.value = FavoritesLoadFailed(userId, _asStorageException(error));
        }
      }
    });
  }

  Future<bool> _mutate({
    required List<PixabayImage> Function(List<PixabayImage> images) optimistic,
    required Future<List<PixabayImage>> Function(String userId) persist,
  }) {
    final userId = _userId;
    if (userId == null) return Future<bool>.value(false);
    final generation = _generation;
    if (state.value case FavoritesLoaded(:final images)) {
      state.value = FavoritesLoaded(userId, optimistic(images));
    }
    _pending++;
    return _enqueue(() async {
      try {
        final images = await persist(userId);
        _pending--;
        if (generation != _generation) return true;
        if (_pending == 0) state.value = FavoritesLoaded(userId, images);
        return true;
      } catch (error) {
        _pending--;
        debugPrint('FavoritesController: write failed: $error');
        if (generation != _generation) return true;
        await _resync(userId, generation);
        return false;
      }
    });
  }

  /// After a failed write the optimistic state may be wrong; storage is the
  /// truth, so read it back.
  Future<void> _resync(String userId, int generation) async {
    try {
      final images = await _repository.load(userId);
      if (generation != _generation || _pending > 0) return;
      state.value = FavoritesLoaded(userId, images);
    } catch (error) {
      if (generation == _generation) {
        state.value = FavoritesLoadFailed(userId, _asStorageException(error));
      }
    }
  }

  /// Runs [operation] after everything queued before it. The chain itself
  /// never stays rejected, so one unexpected error cannot stall later work.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final run = _queue.then((_) => operation());
    _queue = run.then<void>((_) {}, onError: (Object error) {});
    return run;
  }
}

/// Anything that is not already a storage failure is reported as one: an
/// unexpected error must reach the error view, never the zone handler.
FavoritesStorageException _asStorageException(Object error) =>
    error is FavoritesStorageException
    ? error
    : FavoritesStorageException(
        operation: FavoritesStorageOperation.read,
        cause: error,
      );
