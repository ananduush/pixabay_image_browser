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

  static const Duration debounceDuration = Duration(milliseconds: 400);

  final Rx<GalleryState> state = Rx<GalleryState>(const GalleryLoading());

  final TextEditingController searchController = TextEditingController();

  final FocusNode searchFocus = FocusNode();

  // last curated page, restored on clear
  List<PixabayImage>? _exploreImages;

  Timer? _debounce;

  // bumped per request so stale responses are dropped
  int _requestId = 0;

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

  /// curated feed
  Future<void> loadImages() => _load('');

  void onQueryChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      _showExplore();
      return;
    }
    if (_isSettled(query)) return;
    _debounce = Timer(debounceDuration, () => unawaited(_load(query)));
  }

  /// immediate search, no debounce
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

  /// clear pill, keeps keyboard
  void clearSearch() {
    _debounce?.cancel();
    // doesn't fire onChanged
    searchController.clear();
    _showExplore();
  }

  /// cancel / back to browsing, drops keyboard
  void cancelSearch() {
    clearSearch();
    searchFocus.unfocus();
  }

  /// try again, whatever the field holds now
  Future<void> retry() {
    final text = searchController.text.trim();
    if (text.isEmpty) {
      _debounce?.cancel();
      return loadImages();
    }
    return search(text);
  }

  // failures and zero hits can be re-run
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
      // cache even if stale, clear can reuse it
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
      // rethrow so they stay visible to crash reporting.
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
