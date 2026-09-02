import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';
import 'package:pixabay_image_browser/features/gallery/repositories/gallery_repository.dart';
import 'package:pixabay_image_browser/features/gallery/services/pixabay_exception.dart';
import 'package:pixabay_image_browser/features/gallery/views/gallery_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_error_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_search_field.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_skeleton.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/glass_tab_bar.dart';

class _MockRepository extends Mock implements GalleryRepository {}

void main() {
  late _MockRepository repository;

  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.testMode = true;
    repository = _MockRepository();
  });

  tearDown(Get.reset);

  Future<void> pumpGallery(WidgetTester tester) async {
    Get.put(GalleryController(repository: repository));
    await tester.pumpWidget(const GetMaterialApp(home: GalleryView()));
    await tester.pump();
  }

  testWidgets('shows the skeleton while the first page is loading', (
    tester,
  ) async {
    final never = Completer<PixabayPage>();
    when(repository.getImages).thenAnswer((_) => never.future);

    await pumpGallery(tester);

    expect(find.text('Aperture'), findsOneWidget);
    expect(find.byType(GallerySkeleton), findsOneWidget);
    expect(find.byType(GallerySearchField), findsOneWidget);
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(find.text(GalleryErrorView.retryLabel), findsNothing);
  });

  testWidgets('shows the offline screen and retries on tap', (tester) async {
    when(repository.getImages).thenAnswer(
      (_) => Future<PixabayPage>.error(const PixabayNetworkException()),
    );

    await pumpGallery(tester);

    expect(find.text(GalleryErrorView.offlineTitle), findsOneWidget);
    expect(find.byType(GallerySearchField), findsNothing);

    await tester.tap(find.text(GalleryErrorView.retryLabel));
    await tester.pump();

    verify(repository.getImages).called(2);
  });

  testWidgets('shows the API error screen with the request label', (
    tester,
  ) async {
    when(repository.getImages).thenAnswer(
      (_) => Future<PixabayPage>.error(
        const PixabayApiException(statusCode: 500, path: '/api/?q=popular'),
      ),
    );

    await pumpGallery(tester);

    expect(find.text(GalleryErrorView.apiTitle), findsOneWidget);
    expect(find.text('HTTP 500 · /api/?q=popular'), findsOneWidget);
    expect(find.text(GalleryErrorView.retryLabel), findsOneWidget);
  });

  testWidgets('shows the missing-key instructions without a retry button', (
    tester,
  ) async {
    when(repository.getImages).thenAnswer(
      (_) => Future<PixabayPage>.error(const PixabayMissingKeyException()),
    );

    await pumpGallery(tester);

    expect(find.text(GalleryErrorView.missingKeyTitle), findsOneWidget);
    expect(
      find.textContaining('--dart-define=PIXABAY_API_KEY'),
      findsOneWidget,
    );
    expect(find.text(GalleryErrorView.retryLabel), findsNothing);
  });
}
