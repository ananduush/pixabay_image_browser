import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/core/routes/app_pages.dart';
import 'package:pixabay_image_browser/core/routes/app_routes.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_controller.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_state.dart';
import 'package:pixabay_image_browser/features/auth/repositories/auth_repository.dart';
import 'package:pixabay_image_browser/features/favorites/controllers/favorites_controller.dart';
import 'package:pixabay_image_browser/features/favorites/controllers/favorites_state.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';
import 'package:pixabay_image_browser/features/gallery/repositories/gallery_repository.dart';
import 'package:pixabay_image_browser/features/gallery/views/gallery_view.dart';
import 'package:pixabay_image_browser/features/gallery/views/image_detail_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_skeleton.dart';
import 'package:pixabay_image_browser/features/home/views/home_view.dart';
import 'package:pixabay_image_browser/main.dart';

import 'support/auth_fixtures.dart';
import 'support/favorites_fixtures.dart';

class _MockRepository extends Mock implements GalleryRepository {}

void main() {
  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() => Get.testMode = true);

  tearDown(Get.reset);

  _MockRepository pendingGallery() {
    final repository = _MockRepository();
    when(
      repository.getImages,
    ).thenAnswer((_) => Completer<PixabayPage>().future);
    Get.put<GalleryRepository>(repository);
    registerFavoritesFakes();
    return repository;
  }

  void guestAuth() {
    Get.put<AuthRepository>(stubAuthRepository(MockAuthRepository()));
  }

  testWidgets('boots through the route table and both bindings', (
    tester,
  ) async {
    final repository = pendingGallery();
    guestAuth();

    await tester.pumpWidget(const ApertureApp());
    await tester.pump();

    expect(find.byType(HomeView), findsOneWidget);
    expect(find.byType(GalleryView), findsOneWidget);
    expect(find.byType(GallerySkeleton), findsOneWidget);
    expect(Get.isRegistered<AuthController>(), isTrue);
    expect(Get.find<AuthController>().state.value, isA<AuthGuest>());
    expect(Get.isRegistered<GalleryController>(), isTrue);
    expect(Get.isRegistered<FavoritesController>(), isTrue);
    expect(
      Get.find<FavoritesController>().state.value,
      const FavoritesInactive(),
    );
    // Proves the binding built the controller with the injected repository.
    verify(repository.getImages).called(1);
  });

  testWidgets('boots without Supabase configuration; only accounts degrade', (
    tester,
  ) async {
    pendingGallery();
    await tester.pumpWidget(const ApertureApp());
    await tester.pump();

    expect(find.byType(GalleryView), findsOneWidget);
    expect(Get.find<AuthController>().state.value, isA<AuthUnavailable>());
    expect(
      Get.find<FavoritesController>().state.value,
      const FavoritesInactive(),
    );
  });

  test('the route table names the home, auth, details and viewer pages', () {
    expect(
      AppPages.pages.map((GetPage<dynamic> page) => page.name),
      containsAll(<String>[
        AppRoutes.home,
        AppRoutes.auth,
        AppRoutes.imageDetail,
        AppRoutes.imageViewer,
      ]),
    );
  });

  testWidgets('the details route without an image shows the missing view', (
    tester,
  ) async {
    pendingGallery();
    guestAuth();
    await tester.pumpWidget(const ApertureApp());
    await tester.pump();

    Get.toNamed<void>(AppRoutes.imageDetail);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ImageDetailMissingView), findsOneWidget);
    expect(find.text(ImageDetailMissingView.missingTitle), findsOneWidget);
  });
}
