import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/core/routes/app_pages.dart';
import 'package:pixabay_image_browser/core/routes/app_routes.dart';
import 'package:pixabay_image_browser/core/widgets/filled_pill_button.dart';
import 'package:pixabay_image_browser/features/auth/bindings/auth_binding.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_controller.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/auth/repositories/auth_repository.dart';
import 'package:pixabay_image_browser/features/auth/services/auth_exception.dart';
import 'package:pixabay_image_browser/features/auth/views/auth_view.dart';
import 'package:pixabay_image_browser/features/auth/widgets/auth_error_row.dart';
import 'package:pixabay_image_browser/features/auth/widgets/auth_mode_link.dart';

import '../../../support/auth_fixtures.dart';

void main() {
  late MockAuthRepository repository;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.testMode = true;
    repository = MockAuthRepository();
  });

  tearDown(Get.reset);

  Future<AuthController> pumpAuth(
    WidgetTester tester, {
    bool unconfigured = false,
  }) async {
    if (unconfigured) {
      when(
        repository.userChanges,
      ).thenThrow(const AuthMissingConfigException());
    } else {
      stubAuthRepository(repository);
    }
    Get.put<AuthRepository>(repository);
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: AuthBinding(),
        home: const Scaffold(body: SizedBox()),
        getPages: AppPages.pages,
      ),
    );
    Get.toNamed<void>(AppRoutes.auth);
    await tester.pumpAndSettle();
    expect(find.byType(AuthView), findsOneWidget);
    return Get.find<AuthController>();
  }

  Finder field(int index) => find.byType(TextField).at(index);

  Finder cta(String label) => find.widgetWithText(FilledPillButton, label);

  Future<void> fill(
    WidgetTester tester, {
    required String email,
    required String password,
    String? confirm,
  }) async {
    await tester.enterText(field(0), email);
    await tester.enterText(field(1), password);
    if (confirm != null) await tester.enterText(field(2), confirm);
    await tester.pump();
  }

  void stubSignIn(Future<AuthUser> Function() answer) {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => answer());
  }

  String linkFor(bool creating) => creating
      ? '${AuthModeLink.toSignInPrompt} ${AuthModeLink.toSignInAction}'
      : '${AuthModeLink.toCreatePrompt} ${AuthModeLink.toCreateAction}';

  testWidgets('shows the sign-in form', (tester) async {
    await pumpAuth(tester);

    expect(find.text(AuthView.signInLead), findsOneWidget);
    expect(find.text(AuthView.emailLabel.toUpperCase()), findsOneWidget);
    expect(find.text(AuthView.passwordLabel.toUpperCase()), findsOneWidget);
    expect(find.text(AuthView.confirmLabel.toUpperCase()), findsNothing);
    expect(cta(AuthView.signInAction), findsOneWidget);
    expect(find.bySemanticsLabel(linkFor(false)), findsOneWidget);
    expect(find.bySemanticsLabel(AuthView.backLabel), findsOneWidget);
  });

  testWidgets('submitting an empty form explains what is missing', (
    tester,
  ) async {
    await pumpAuth(tester);

    await tester.tap(cta(AuthView.signInAction));
    await tester.pump();

    expect(find.text(AuthErrorRow.incompleteCopy), findsOneWidget);
    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('the mode link switches to Create account and back', (
    tester,
  ) async {
    await pumpAuth(tester);

    await tester.tap(find.bySemanticsLabel(linkFor(false)));
    await tester.pump();

    expect(find.text(AuthView.createLead), findsOneWidget);
    expect(find.text(AuthView.confirmLabel.toUpperCase()), findsOneWidget);
    expect(find.text(AuthView.passwordRule), findsOneWidget);
    expect(cta(AuthView.createAction), findsOneWidget);

    await fill(
      tester,
      email: 'new@aperture.app',
      password: 'password1',
      confirm: 'password2',
    );
    await tester.tap(cta(AuthView.createAction));
    await tester.pump();
    expect(find.text(AuthErrorRow.passwordMismatchCopy), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(linkFor(true)));
    await tester.pump();
    expect(find.text(AuthView.signInLead), findsOneWidget);
    expect(
      tester.widget<TextField>(field(0)).controller?.text,
      'new@aperture.app',
    );
  });

  testWidgets('a rejected sign-in shows the copy and keeps the fields', (
    tester,
  ) async {
    await pumpAuth(tester);
    stubSignIn(() async => throw const AuthInvalidCredentialsException());
    await fill(tester, email: 'sam@aperture.app', password: 'wrong');

    await tester.tap(cta(AuthView.signInAction));
    await tester.pump();

    expect(find.text(AuthErrorRow.invalidCredentialsCopy), findsOneWidget);
    expect(find.byType(AuthView), findsOneWidget);
    expect(
      tester.widget<TextField>(field(0)).controller?.text,
      'sam@aperture.app',
    );
    expect(tester.widget<TextField>(field(1)).controller?.text, 'wrong');

    await tester.enterText(field(1), 'wrong2');
    await tester.pump();
    expect(find.text(AuthErrorRow.invalidCredentialsCopy), findsNothing);
  });

  testWidgets('a successful sign-in pops back to where it was opened', (
    tester,
  ) async {
    final auth = await pumpAuth(tester);
    stubSignIn(() async => sampleUser());
    await fill(tester, email: 'sam@aperture.app', password: 'correct horse');

    await tester.tap(cta(AuthView.signInAction));
    await tester.pumpAndSettle();

    expect(find.byType(AuthView), findsNothing);
    expect(auth.state.value.isAuthenticated, isTrue);
    verify(
      () => repository.signIn(
        email: 'sam@aperture.app',
        password: 'correct horse',
      ),
    ).called(1);
  });

  testWidgets('shows the busy label and ignores a second tap', (tester) async {
    await pumpAuth(tester);
    final pending = Completer<AuthUser>();
    stubSignIn(() => pending.future);
    await fill(tester, email: 'sam@aperture.app', password: 'pw');

    await tester.tap(cta(AuthView.signInAction));
    await tester.pump();

    expect(find.text(AuthView.signInBusy), findsOneWidget);
    await tester.tap(cta(AuthView.signInBusy));
    await tester.pump();

    pending.complete(sampleUser());
    await tester.pumpAndSettle();
    verify(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
    expect(find.byType(AuthView), findsNothing);
  });

  testWidgets('fits a narrow phone with the keyboard up', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);

    await pumpAuth(tester);
    final link = find.bySemanticsLabel(linkFor(false), skipOffstage: false);
    await tester.ensureVisible(link);
    await tester.pump();
    await tester.tap(link);
    await tester.pump();
    expect(tester.takeException(), isNull);

    final action = find.widgetWithText(
      FilledPillButton,
      AuthView.createAction,
      skipOffstage: false,
    );
    await tester.ensureVisible(action);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(cta(AuthView.createAction), findsOneWidget);
  });

  testWidgets('without configuration the form is replaced by instructions', (
    tester,
  ) async {
    await pumpAuth(tester, unconfigured: true);

    expect(find.text(AuthView.unavailableTitle), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.bySemanticsLabel(AuthView.backLabel), findsOneWidget);
  });
}
