import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../repositories/gallery_repository.dart';
import '../services/pixabay_exception.dart';
import 'gallery_state.dart';

class GalleryController extends GetxController {
  GalleryController({required this._repository});

  final GalleryRepository _repository;

  final Rx<GalleryState> state = Rx<GalleryState>(const GalleryLoading());

  @override
  void onInit() {
    super.onInit();
    unawaited(loadImages());
  }

  /// Loads the first page of the feed. Also the retry action.
  Future<void> loadImages() async {
    state.value = const GalleryLoading();
    try {
      final page = await _repository.getImages();
      state.value = GalleryLoaded(page.hits);
    } on PixabayException catch (error) {
      if (error is PixabayMissingKeyException) debugPrint(error.message);
      state.value = GalleryFailure(error);
    }
  }
}
