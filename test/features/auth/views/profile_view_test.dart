import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/core/widgets/filled_pill_button.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_controller.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/auth/services/auth_exception.dart';
import 'package:pixabay_image_browser/features/auth/views/profile_view.dart';
import 'package:pixabay_image_browser/features/auth/widgets/profile_identity.dart';
import 'package:pixabay_image_browser/features/favorites/controllers/favorites_controller.dart';
import 'package:pixabay_image_browser/features/favorites/repositories/favorites_repository.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/home/controllers/home_controller.dart';
import 'package:pixabay_image_browser/core/widgets/glass_tab_bar.dart';

import '../../../support/auth_fixtures.dart';
import '../../../support/favorites_fixtures.dart';
import '../../../support/pixabay_fixtures.dart';

class _MockGalleryController extends Mock implements GalleryController {}

void main() {
  late MockAuthRepository repository;
  late FakeFavoritesStorageService storage;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.testMode = true;
    repository = MockAuthRepository();
    storage = FakeFavoritesStorageService();
  });

  tearDown(Get.reset);

  Future<AuthController> pumpProfile(
    WidgetTester tester, {
    AuthUser? user,
    bool unconfigured = false,
    List<PixabayImage> saved = const <PixabayImage>[],
  }) async {
    if (user != null) storage.seed(user.id, saved);
    if (unconfigured) {
      when(
        repository.userChanges,
      ).thenThrow(const AuthMissingConfigException());
    } else {
      stubAuthRepository(repository, user: user);
    }
    final controller = Get.put(AuthController(repository: repository));
    addTearDown(controller.onClose);
    Get.put(
      FavoritesController(
        auth: controller,
        repository: FavoritesRepository(storage: storage),
      ),
    );
    Get.put(
      HomeController(auth: controller, gallery: _MockGalleryController()),
    );
    await tester.pumpWidget(const GetMaterialApp(home: ProfileView()));
    await tester.pump();
    await tester.pump();
    return controller;
  }

  testWidgets('renders the logged-out state with a Sign in action', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text(ProfileView.title), findsOneWidget);
    expect(find.text(ProfileView.guestHeading), findsOneWidget);
    expect(find.text(ProfileView.guestBody), findsOneWidget);
    expect(
      find.widgetWithText(FilledPillButton, ProfileView.signInLabel),
      findsOneWidget,
    );
    expect(find.text(ProfileView.sourceValue), findsOneWidget);
    expect(find.text(ProfileView.version), findsOneWidget);
    expect(find.text(ProfileView.logOutLabel), findsNothing);
  });

  testWidgets('renders the signed-in account from the Supabase session', (
    tester,
  ) async {
    final user = sampleUser();
    await pumpProfile(tester, user: user);

    expect(find.text(user.email), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(
      find.text(ProfileIdentity.joinedLabel(user.createdAt ?? DateTime(0))),
      findsOneWidget,
    );
    expect(find.text(ProfileView.logOutLabel), findsOneWidget);
    expect(find.text(ProfileView.guestHeading), findsNothing);
    expect(
      find.widgetWithText(FilledPillButton, ProfileView.signInLabel),
      findsNothing,
    );
  });

  testWidgets('Log out runs the auth flow and returns to logged out', (
    tester,
  ) async {
    await pumpProfile(tester, user: sampleUser());
    when(repository.signOut).thenAnswer((_) async {
      when(repository.currentUser).thenReturn(null);
    });

    await tester.tap(find.text(ProfileView.logOutLabel));
    await tester.pump();

    verify(repository.signOut).called(1);
    expect(find.text(ProfileView.guestHeading), findsOneWidget);
    expect(find.text(ProfileView.logOutLabel), findsNothing);
  });

  testWidgets('Log out shows its busy label while the request runs', (
    tester,
  ) async {
    await pumpProfile(tester, user: sampleUser());
    final pending = Completer<void>();
    when(repository.signOut).thenAnswer((_) => pending.future);

    await tester.tap(find.text(ProfileView.logOutLabel));
    await tester.pump();

    expect(find.text(ProfileView.loggingOutLabel), findsOneWidget);

    when(repository.currentUser).thenReturn(null);
    pending.complete();
    await tester.pump();

    expect(find.text(ProfileView.guestHeading), findsOneWidget);
  });

  testWidgets('explains the missing configuration instead of a Sign in', (
    tester,
  ) async {
    await pumpProfile(tester, unconfigured: true);

    expect(find.text(ProfileView.unavailableHeading), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
    expect(
      find.widgetWithText(FilledPillButton, ProfileView.signInLabel),
      findsNothing,
    );
  });

  testWidgets('signed in, the Saved images row counts and opens Favourites', (
    tester,
  ) async {
    await pumpProfile(
      tester,
      user: sampleUser(),
      saved: <PixabayImage>[
        PixabayImage.fromJson(sampleHit(id: 1)),
        PixabayImage.fromJson(sampleHit(id: 2)),
      ],
    );

    expect(find.text(ProfileView.savedImagesLabel), findsOneWidget);
    expect(find.text(ProfileView.savedImagesValue(2)), findsOneWidget);
    expect(find.text(ProfileView.logoutFootnote), findsOneWidget);

    await tester.tap(find.text(ProfileView.savedImagesLabel));
    await tester.pump();

    expect(Get.find<HomeController>().tab.value, AppTab.favourites);
  });

  testWidgets('the guest profile has no Saved images row', (tester) async {
    await pumpProfile(tester);

    expect(find.text(ProfileView.savedImagesLabel), findsNothing);
    expect(find.text(ProfileView.logoutFootnote), findsNothing);
  });
}
