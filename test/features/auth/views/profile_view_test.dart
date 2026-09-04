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

import '../../../support/auth_fixtures.dart';

void main() {
  late MockAuthRepository repository;

  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.testMode = true;
    repository = MockAuthRepository();
  });

  tearDown(Get.reset);

  Future<AuthController> pumpProfile(
    WidgetTester tester, {
    AuthUser? user,
    bool unconfigured = false,
  }) async {
    if (unconfigured) {
      when(
        repository.userChanges,
      ).thenThrow(const AuthMissingConfigException());
    } else {
      stubAuthRepository(repository, user: user);
    }
    final controller = Get.put(AuthController(repository: repository));
    addTearDown(controller.onClose);
    await tester.pumpWidget(const GetMaterialApp(home: ProfileView()));
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
}
