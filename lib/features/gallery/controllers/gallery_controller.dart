import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../models/pixabay_image.dart';
import '../repositories/gallery_repository.dart';
import '../services/pixabay_exception.dart';
import 'gallery_state.dart';

class GalleryController extends GetxController {
  GalleryController({required this._repository});

  final GalleryRepository _repository;

  /// Pause in typing before a search is sent (the design's "debounced
  /// 400ms").
  static const Duration debounceDuration = Duration(milliseconds: 400);

  final Rx<GalleryState> state = Rx<GalleryState>(const GalleryLoading());

  /// Owned here so [search] and [clearSearch] can drive the field and the
  /// text outlives any view rebuild. Disposed in [onClose].
  final TextEditingController searchController = TextEditingController();

  /// Owned here so leaving a search (Cancel, "Back to browsing") can also
  /// dismiss the keyboard.
  final FocusNode searchFocus = FocusNode();

  /// Last successful curated page, restored instantly when a search is
  /// cleared.
  List<PixabayImage>? _exploreImages;

  Timer? _debounce;

  /// Generation token: every request bumps it, and a response only lands if
  /// it still belongs to the latest generation. Clearing a search bumps it
  /// too, so a late search response can never overwrite the feed.
  int _requestId = 0;

  /// The key is a compile-time constant, so the missing-key screen is logged
  /// once rather than on every typing pause.
  bool _loggedMissingKey = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadImages());
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  /// Loads the first page of the curated feed: initial load, and the
  /// Explore restore when no cached page exists.
  Future<void> loadImages() => _load('');

  /// Wired to the field's `onChanged`. Whitespace-only text is Explore.
  void onQueryChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      _showExplore();
      return;
    }
    // Retyping the term already shown (or adding trailing spaces) is a
    // no-op rather than a duplicate request.
    if (_isSettled(query)) return;
    _debounce = Timer(debounceDuration, () => unawaited(_load(query)));
  }

  /// Searches [query] immediately (suggestion pills, keyboard search key),
  /// mirroring it into the field.
  Future<void> search(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (searchController.text != trimmed) {
      searchController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }
    if (trimmed.isEmpty) {
      _showExplore();
      return Future<void>.value();
    }
    if (_isSettled(trimmed)) return Future<void>.value();
    return _load(trimmed);
  }

  /// The clear pill: back to the curated feed, keyboard still up so the
  /// user can type the next term straight away.
  void clearSearch() {
    _debounce?.cancel();
    // Programmatic changes do not fire TextField.onChanged.
    searchController.clear();
    _showExplore();
  }

  /// Cancel and "Back to browsing": leave search entirely, keyboard down.
  void cancelSearch() {
    clearSearch();
    searchFocus.unfocus();
  }

  /// "Try again": re-runs what the field currently holds — the failed
  /// search, or the curated feed when the field is empty. Anything typed
  /// since the failure wins over the failed term, so the field and the
  /// results never disagree.
  Future<void> retry() {
    final text = searchController.text.trim();
    if (text.isEmpty) {
      _debounce?.cancel();
      return loadImages();
    }
    return search(text);
  }

  /// Whether [query] is already being loaded or shown with results, so a
  /// request for it would be a duplicate. Failures and zero-hit results are
  /// not settled: retyping or re-picking the same term runs it again.
  bool _isSettled(String query) {
    final current = state.value;
    if (current.query != query) return false;
    return switch (current) {
      GalleryLoading() => true,
      GalleryLoaded(:final images) => images.isNotEmpty,
      GalleryFailure() => false,
    };
  }

  void _showExplore() {
    // Already Explore (loading, loaded or failed): nothing to cancel or
    // fetch. A pending debounce was cancelled by the caller.
    if (!state.value.isSearch) return;
    _requestId++;
    final cached = _exploreImages;
    if (cached != null) {
      state.value = GalleryLoaded(cached);
    } else {
      unawaited(loadImages());
    }
  }

  Future<void> _load(String query) async {
    final id = ++_requestId;
    state.value = GalleryLoading(query: query);
    try {
      final page = await _repository.getImages(
        query: query.isEmpty ? null : query,
      );
      // A curated page is worth keeping even when a search has since
      // superseded it: clearing that search can then restore the feed
      // without another request.
      if (query.isEmpty) _exploreImages = page.hits;
      if (id != _requestId) return;
      state.value = GalleryLoaded(
        page.hits,
        query: query,
        totalHits: page.totalHits,
      );
    } on PixabayException catch (error) {
      if (error is PixabayMissingKeyException && !_loggedMissingKey) {
        _loggedMissingKey = true;
        debugPrint(error.message);
      }
      if (id != _requestId) return;
      state.value = GalleryFailure(error, query: query);
    } catch (error) {
      // Unexpected errors still get an error screen (onInit fires this
      // unawaited, so without this the skeleton would spin forever), but
      // rethrow so they stay visible to crash reporting. Never overwrite a
      // newer request's state.
      if (id == _requestId) {
        state.value = GalleryFailure(
          PixabayUnexpectedException('$error'),
          query: query,
        );
      }
      rethrow;
    }
  }
}
