import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/filled_pill_button.dart';
import '../../gallery/widgets/gallery_state_view.dart';
import '../controllers/auth_form_controller.dart';
import '../controllers/auth_form_state.dart';
import '../controllers/auth_state.dart';
import '../widgets/auth_error_row.dart';
import '../widgets/auth_mode_link.dart';
import '../widgets/auth_text_field.dart';

class AuthView extends GetView<AuthFormController> {
  const AuthView({super.key});

  static const String signInTitle = 'Sign in';
  static const String createTitle = 'Create account';
  static const String signInLead =
      'Signing in unlocks Favourites. Saved images are kept on this device '
      'and stay available offline.';
  static const String createLead =
      'Create an account to unlock Favourites. Saved images are kept on this '
      'device and stay available offline.';

  static const String emailLabel = 'Email';
  static const String emailHint = 'you@example.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = '••••••••';
  static const String confirmLabel = 'Confirm password';
  static const String passwordRule =
      'At least ${AuthFormController.minPasswordLength} characters.';

  static const String signInAction = 'Sign in';
  static const String signInBusy = 'Signing in';
  static const String createAction = 'Create account';
  static const String createBusy = 'Creating account';

  static const String backLabel = 'Back';

  static const String unavailableTitle = 'Accounts are not configured';

  static const double backTopInset = 10;
  static const double backLeftInset = 16;

  Future<void> _submit() async {
    if (await controller.submit()) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          if (controller.authState case AuthUnavailable(:final error)) {
            return Stack(
              children: <Widget>[
                GalleryStateView(
                  glyph: const Icon(
                    Icons.person_off_outlined,
                    size: 34,
                    color: AppColors.rule35,
                  ),
                  title: unavailableTitle,
                  body: error.message,
                ),
                const Positioned(
                  top: backTopInset,
                  left: backLeftInset,
                  child: _BackButton(),
                ),
              ],
            );
          }
          return _Form(controller: controller, onSubmit: _submit);
        }),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller, required this.onSubmit});

  final AuthFormController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final creating = controller.mode.value == AuthMode.createAccount;
      final issue = controller.issue.value;
      final failure = controller.failure;
      final message = issue != null
          ? AuthErrorRow.issueCopy(issue)
          : failure != null
          ? AuthErrorRow.errorCopy(failure)
          : null;
      return _layout(creating: creating, message: message);
    });
  }

  Widget _layout({required bool creating, required String? message}) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(
              top: AuthView.backTopInset,
              left: AuthView.backLeftInset,
            ),
            child: Align(alignment: Alignment.centerLeft, child: _BackButton()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  creating ? AuthView.createTitle : AuthView.signInTitle,
                  style: AppTypography.screenTitle,
                ),
                const SizedBox(height: 10),
                Text(
                  creating ? AuthView.createLead : AuthView.signInLead,
                  style: AppTypography.lead,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              30,
              AppSpacing.gutter,
              40,
            ),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AuthTextField(
                    label: AuthView.emailLabel,
                    hint: AuthView.emailHint,
                    controller: controller.emailController,
                    focusNode: controller.emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
                    onSubmitted: (_) => controller.passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: AuthView.passwordLabel,
                    hint: AuthView.passwordHint,
                    controller: controller.passwordController,
                    focusNode: controller.passwordFocus,
                    obscureText: true,
                    textInputAction: creating
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: <String>[
                      creating
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    onSubmitted: (_) => creating
                        ? controller.confirmFocus.requestFocus()
                        : onSubmit(),
                    hintBelow: creating ? AuthView.passwordRule : null,
                  ),
                  if (creating) ...<Widget>[
                    const SizedBox(height: 24),
                    AuthTextField(
                      label: AuthView.confirmLabel,
                      hint: AuthView.passwordHint,
                      controller: controller.confirmController,
                      focusNode: controller.confirmFocus,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ],
                  if (message != null) ...<Widget>[
                    const SizedBox(height: 16),
                    AuthErrorRow(message: message),
                  ],
                  const SizedBox(height: 24),
                  FilledPillButton(
                    label: creating
                        ? AuthView.createAction
                        : AuthView.signInAction,
                    busyLabel: creating
                        ? AuthView.createBusy
                        : AuthView.signInBusy,
                    busy: controller.isBusy,
                    enabled: controller.canSubmit.value,
                    onPressed: onSubmit,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AuthModeLink(
                    mode: controller.mode.value,
                    onTap: controller.toggleMode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AuthView.backLabel,
      child: GestureDetector(
        onTap: Get.back<void>,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.square(
          dimension: size,
          child: Icon(Icons.arrow_back_ios_new, size: 15, color: AppColors.ink),
        ),
      ),
    );
  }
}
