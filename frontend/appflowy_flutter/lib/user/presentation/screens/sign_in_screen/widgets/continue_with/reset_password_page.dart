import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/password/password_http_service.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/back_to_login_in_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/title_logo.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/verifying_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.backToLogin,
    required this.email,
    required this.baseUrl,
  });

  final String email;
  final VoidCallback backToLogin;
  final String baseUrl;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passcodeController = TextEditingController();

  bool isEnteringPasscode = true;

  ToastificationItem? toastificationItem;

  final inputPasscodeKey = GlobalKey<AFTextFieldState>();

  bool isSubmitting = false;

  late final PasswordHttpService resetPasswordService = PasswordHttpService(
    baseUrl: widget.baseUrl,
    // leave the auth token empty, the user is not signed in yet
    authToken: '',
  );

  @override
  void dispose() {
    passcodeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        final successOrFail = state.successOrFail;
        if (successOrFail != null && successOrFail.isFailure) {
          successOrFail.onFailure((error) {
            inputPasscodeKey.currentState?.syncError(
              errorText: LocaleKeys.signIn_tokenHasExpiredOrInvalid.tr(),
            );
          });
        }

        if (state.isSubmitting != isSubmitting) {
          setState(() => isSubmitting = state.isSubmitting);
        }
      },
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo, title and description
                _buildLogoTitleAndDescription(),

                // Enter code manually
                ..._buildEnterCodeManually(),

                // Back to login
                BackToLoginButton(
                  onTap: widget.backToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEnterCodeManually() {
    // todo: ask designer to provide the spacing
    final spacing = VSpace(20);

    return [
      // Enter code manually
      AFTextField(
        key: inputPasscodeKey,
        controller: passcodeController,
        hintText: LocaleKeys.signIn_enterCode.tr(),
        keyboardType: TextInputType.number,
        autoFocus: true,
        onSubmitted: (passcode) {
          if (passcode.isEmpty) {
            inputPasscodeKey.currentState?.syncError(
              errorText: LocaleKeys.signIn_invalidVerificationCode.tr(),
            );
          } else {
            //
          }
        },
      ),
      // todo: ask designer to provide the spacing
      VSpace(12),

      // continue to login
      isSubmitting
          ? const VerifyingButton()
          : ContinueWithButton(
              text: LocaleKeys.signIn_continueToSignIn.tr(),
              onTap: () {
                final passcode = passcodeController.text;
                if (passcode.isEmpty) {
                  inputPasscodeKey.currentState?.syncError(
                    errorText: LocaleKeys.signIn_invalidVerificationCode.tr(),
                  );
                } else {
                  _onSubmit();
                }
              },
            ),

      spacing,
    ];
  }

  Widget _buildLogoTitleAndDescription() {
    final theme = AppFlowyTheme.of(context);
    return TitleLogo(
      title: LocaleKeys.signIn_checkYourEmail.tr(),
      description: LocaleKeys.signIn_temporaryVerificationLinkSent.tr(),
      informationBuilder: (context) => Text(
        widget.email,
        style: theme.textStyle.body.enhanced(
          color: theme.textColorScheme.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _onSubmit() async {
    final passcode = passcodeController.text;
    if (passcode.isEmpty) {
      inputPasscodeKey.currentState?.syncError(
        errorText: LocaleKeys.signIn_invalidVerificationCode.tr(),
      );
      return;
    }

    // final signInBloc = context.read<SignInBloc>();
    // final result = await forgotPasswordService.forgotPassword(email: email);
  }
}
