import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/core/routes/app_pages.dart';
import 'package:pixabay_image_browser/core/routes/app_routes.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';
import 'package:pixabay_image_browser/features/gallery/repositories/gallery_repository.dart';
import 'package:pixabay_image_browser/features/gallery/views/gallery_view.dart';
import 'package:pixabay_image_browser/features/gallery/views/image_detail_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_skeleton.dart';
import 'package:pixabay_image_browser/main.dart';

class _MockRepository extends Mock implements GalleryRepository {}

void main() {
  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() => Get.testMode = true);

  tearDown(Get.reset);

  testWidgets('boots through the route table and gallery binding', (
    tester,
  ) async {
    // A dependency that is already registered wins over GalleryBinding's
    // lazyPut, so the real route → binding → controller wiring runs while
    // the repository stays offline. The never-completing future keeps the
    // screen on the skeleton, so no image requests are attempted either.
    final repository = _MockRepository();
    when(
      repository.getImages,
    ).thenAnswer((_) => Completer<PixabayPage>().future);
    Get.put<GalleryRepository>(repository);

    await tester.pumpWidget(const ApertureApp());
    await tester.pump();

    expect(find.byType(GalleryView), findsOneWidget);
    expect(find.byType(GallerySkeleton), findsOneWidget);
    expect(Get.isRegistered<GalleryController>(), isTrue);
    // Proves the binding built the controller with the injected repository.
    verify(repository.getImages).called(1);
  });

  test('the route table names the gallery, details and viewer pages', () {
    expect(
      AppPages.pages.map((GetPage<dynamic> page) => page.name),
      containsAll(<String>[
        AppRoutes.gallery,
        AppRoutes.imageDetail,
        AppRoutes.imageViewer,
      ]),
    );
  });

  testWidgets('the details route without an image shows the missing view', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(
      repository.getImages,
    ).thenAnswer((_) => Completer<PixabayPage>().future);
    Get.put<GalleryRepository>(repository);
    await tester.pumpWidget(const ApertureApp());
    await tester.pump();

    Get.toNamed<void>(AppRoutes.imageDetail);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ImageDetailMissingView), findsOneWidget);
    expect(find.text(ImageDetailMissingView.missingTitle), findsOneWidget);
  });
}
