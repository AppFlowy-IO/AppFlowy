import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/back_to_login_in_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/title_logo.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/verifying_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SetNewPasswordWidget extends StatefulWidget {
  const SetNewPasswordWidget({
    super.key,
    required this.backToLogin,
    required this.email,
  });

  final String email;
  final VoidCallback backToLogin;

  @override
  State<SetNewPasswordWidget> createState() => _SetNewPasswordWidgetState();
}

class _SetNewPasswordWidgetState extends State<SetNewPasswordWidget> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final newPasswordKey = GlobalKey<AFTextFieldState>();
  final confirmPasswordKey = GlobalKey<AFTextFieldState>();

  bool isSubmitting = false;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final spacing = theme.spacing.xxl;
    return BlocConsumer<SignInBloc, SignInState>(
      listener: (context, state) {
        final successOrFail = state.resetPasswordSuccessOrFail;
        if (successOrFail != null) {
          successOrFail.fold(
            (success) {
              showToastNotification(
                message: LocaleKeys.signIn_resetPasswordSuccess.tr(),
              );
              // pop until the login screen is found
              Navigator.popUntil(context, (route) {
                return route.settings.name == '/continue-with-password';
              });
            },
            (error) {
              if (error.code == ErrorCode.NewPasswordTooWeak) {
                newPasswordKey.currentState?.syncError(
                  errorText: LocaleKeys.signIn_passwordMustContain.tr(),
                );
              } else {
                newPasswordKey.currentState?.syncError(
                  errorText: error.msg,
                );
              }
            },
          );
        }
        // Handle state changes and validation results here
        if (state.isSubmitting != isSubmitting) {
          setState(() => isSubmitting = state.isSubmitting);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogoAndTitle(),
                  _buildPasswordFields(),
                  VSpace(spacing),
                  _buildResetButton(),
                  VSpace(spacing),
                  BackToLoginButton(
                    onTap: widget.backToLogin,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoAndTitle() {
    final theme = AppFlowyTheme.of(context);
    return TitleLogo(
      title: LocaleKeys.signIn_resetPassword.tr(),
      informationBuilder: (context) => RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: LocaleKeys.signIn_enterNewPasswordFor.tr(),
              style: theme.textStyle.body.standard(
                color: theme.textColorScheme.primary,
              ),
            ),
            TextSpan(
              text: widget.email,
              style: theme.textStyle.body.enhanced(
                color: theme.textColorScheme.primary,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPasswordFields() {
    final theme = AppFlowyTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.signIn_newPassword.tr(),
          style: theme.textStyle.caption.enhanced(
            color: theme.textColorScheme.secondary,
          ),
        ),
        const VSpace(8),
        AFTextField(
          key: newPasswordKey,
          controller: newPasswordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          hintText: LocaleKeys.signIn_enterNewPassword.tr(),
          onSubmitted: (_) => _validateAndSubmit(),
        ),
        const VSpace(16),
        Text(
          LocaleKeys.signIn_confirmPassword.tr(),
          style: theme.textStyle.caption.enhanced(
            color: theme.textColorScheme.secondary,
          ),
        ),
        const VSpace(8),
        AFTextField(
          key: confirmPasswordKey,
          controller: confirmPasswordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          hintText: LocaleKeys.signIn_confirmNewPassword.tr(),
          onSubmitted: (_) => _validateAndSubmit(),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return isSubmitting
        ? const VerifyingButton()
        : ContinueWithButton(
            text: LocaleKeys.signIn_resetPassword.tr(),
            onTap: _validateAndSubmit,
          );
  }

  void _validateAndSubmit() {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty) {
      newPasswordKey.currentState?.syncError(
        errorText: LocaleKeys.signIn_newPasswordCannotBeEmpty.tr(),
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordKey.currentState?.syncError(
        errorText: LocaleKeys.signIn_confirmPasswordCannotBeEmpty.tr(),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      confirmPasswordKey.currentState?.syncError(
        errorText: LocaleKeys.signIn_passwordsDoNotMatch.tr(),
      );
      return;
    }

    // Add the reset password event to the bloc
    context.read<SignInBloc>().add(
          ResetPassword(
            email: widget.email,
            newPassword: newPassword,
          ),
        );
  }
}
