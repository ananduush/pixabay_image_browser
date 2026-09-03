import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../models/pixabay_image.dart';
import '../models/pixabay_page.dart';
import '../repositories/gallery_repository.dart';
import '../services/pixabay_exception.dart';
import 'gallery_state.dart';

class GalleryController extends GetxController {
  GalleryController({required this._repository});

  final GalleryRepository _repository;

  static const Duration debounceDuration = Duration(milliseconds: 400);

  static const int perPage = 20;

  static const double loadMoreThreshold = 600;

  static const Duration scrollToTopDuration = Duration(milliseconds: 350);

  final Rx<GalleryState> state = Rx<GalleryState>(const GalleryLoading());

  final TextEditingController searchController = TextEditingController();

  final FocusNode searchFocus = FocusNode();
  final ScrollController scrollController = ScrollController();

  // page-1 explore snapshot, restored on clear
  GalleryLoaded? _exploreFirstPage;

  Timer? _debounce;

  // bumped per request so stale responses are dropped
  int _requestId = 0;

  bool _loggedMissingKey = false;

  // finger down on the feed; a fling's bounce must not count as a pull
  bool _userDragging = false;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    unawaited(loadImages());
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    searchFocus.dispose();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  /// curated feed
  Future<void> loadImages() => _loadFirstPage('');

  void onQueryChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      _showExplore();
      return;
    }
    if (_isSettled(query)) return;
    _debounce = Timer(debounceDuration, () => unawaited(_loadFirstPage(query)));
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
    return _loadFirstPage(trimmed);
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

  /// Next page for the current feed. Single-flight: only an idle feed starts one.
  Future<void> loadMore() {
    switch (state.value) {
      case GalleryLoaded current when current.status is FeedIdle:
        return _loadNextPage(current);
      default:
        return Future<void>.value();
    }
  }

  /// Footer "Try again": the page that just failed, same query.
  Future<void> retryLoadMore() {
    switch (state.value) {
      case GalleryLoaded current when current.status is FeedLoadMoreFailed:
        return _loadNextPage(current);
      default:
        return Future<void>.value();
    }
  }

  /// From the view's scroll notifications: true only while a finger drags.
  void onUserDrag({required bool dragging}) {
    _userDragging = dragging;
  }

  /// The refresh control arms on any overscroll past its trigger, ballistic
  /// bounce included, so only a real pull is allowed to reload.
  Future<void> refreshFromPull() {
    if (!_userDragging) return Future<void>.value();
    return refreshFeed();
  }

  /// Page 1 of the current query again, current images staying visible
  /// meanwhile. Reached only through [refreshFromPull]. (Not `refresh` —
  /// that name is GetX's notifier hook behind `update()`.)
  Future<void> refreshFeed() {
    switch (state.value) {
      case GalleryLoading():
        return Future<void>.value();
      case GalleryFailure():
        return retry();
      case GalleryLoaded(status: FeedRefreshing()):
        return Future<void>.value();
      case GalleryLoaded current:
        return _loadFirstPage(current.query, refreshing: current);
    }
  }

  /// Active-tab tap: back to the header. Leaves query, results and focus alone.
  void scrollToTop() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels <= 0) return;
    unawaited(
      scrollController.animateTo(
        0,
        duration: scrollToTopDuration,
        curve: Curves.easeOutCubic,
      ),
    );
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

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (!position.hasContentDimensions) return;
    if (position.extentAfter < loadMoreThreshold) unawaited(loadMore());
  }

  void _showExplore() {
    if (!state.value.isSearch) return;
    _requestId++;
    final cached = _exploreFirstPage;
    if (cached != null) {
      state.value = cached; // always page 1, FeedIdle or FeedEnd
    } else {
      unawaited(loadImages());
    }
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  Future<void> _loadFirstPage(String query, {GalleryLoaded? refreshing}) async {
    final id = ++_requestId;
    state.value =
        refreshing?.copyWith(status: const FeedRefreshing()) ??
        GalleryLoading(query: query);
    try {
      final response = await _repository.getImages(
        query: query,
        page: 1,
        perPage: perPage,
      );
      final loaded = _loadedFrom(response, query: query, pageNumber: 1);
      if (query.isEmpty) {
        _exploreFirstPage = loaded; // cache even if stale, as today
      }
      if (id != _requestId) return;
      state.value = loaded;
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

  GalleryLoaded _loadedFrom(
    PixabayPage response, {
    required String query,
    required int pageNumber,
    List<PixabayImage> existing = const <PixabayImage>[],
  }) {
    // Ids must be unique across the feed, and within one response too: a
    // repeated id would give two tiles one hero tag and break navigation.
    final seen = existing.toSet();
    final images = <PixabayImage>[...existing];
    for (final hit in response.hits) {
      if (seen.add(hit)) images.add(hit);
    }
    final status =
        (response.hits.isEmpty || pageNumber * perPage >= response.totalHits)
        ? const FeedEnd()
        : const FeedIdle();
    return GalleryLoaded(
      images,
      query: query,
      totalHits: response.totalHits,
      page: pageNumber,
      status: status,
    );
  }

  Future<void> _loadNextPage(GalleryLoaded current) async {
    final id = _requestId; // same generation — do NOT bump
    final next = current.nextPage;
    state.value = current.copyWith(status: const FeedLoadingMore());
    try {
      final response = await _repository.getImages(
        query: current.query,
        page: next,
        perPage: perPage,
      );
      if (!_isStillLoading(id, current)) return;
      state.value = _loadedFrom(
        response,
        query: current.query,
        pageNumber: next,
        existing: current.images,
      );
    } on PixabayException catch (error) {
      if (!_isStillLoading(id, current)) return;
      // Pixabay answers 400 "page is out of valid range" if the count drifted; a retry
      // could only 400 again, so treat it as the end.
      final outOfRange =
          error is PixabayApiException && error.statusCode == 400;
      state.value = current.copyWith(
        status: outOfRange ? const FeedEnd() : FeedLoadMoreFailed(error),
      );
    } catch (error) {
      if (_isStillLoading(id, current)) {
        state.value = current.copyWith(
          status: FeedLoadMoreFailed(PixabayUnexpectedException('$error')),
        );
      }
      rethrow; // same policy as _loadFirstPage: visible to crash reporting
    }
  }

  /// True while the feed this request was started for is still the live one.
  bool _isStillLoading(int id, GalleryLoaded started) {
    if (id != _requestId) return false;
    return switch (state.value) {
      GalleryLoaded(:final query, :final page, status: FeedLoadingMore()) =>
        query == started.query && page == started.page,
      _ => false,
    };
  }
}
