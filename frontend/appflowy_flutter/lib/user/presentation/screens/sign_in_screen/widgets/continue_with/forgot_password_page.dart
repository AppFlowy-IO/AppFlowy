import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/password/password_http_service.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/back_to_login_in_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/reset_password_page.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/title_logo.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/verifying_button.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    required this.backToLogin,
    required this.email,
    required this.baseUrl,
  });

  final String email;
  final VoidCallback backToLogin;
  final String baseUrl;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final passwordController = TextEditingController();
  final inputPasswordKey = GlobalKey<AFTextFieldState>();

  bool isSubmitting = false;

  late final PasswordHttpService forgotPasswordService = PasswordHttpService(
    baseUrl: widget.baseUrl,
    // leave the auth token empty, the user is not signed in yet
    authToken: '',
  );

  @override
  void initState() {
    super.initState();

    passwordController.text = widget.email;
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: BlocListener<SignInBloc, SignInState>(
            listener: (context, state) {
              final successOrFail = state.successOrFail;
              if (successOrFail != null && successOrFail.isFailure) {
                successOrFail.onFailure((error) {
                  inputPasswordKey.currentState?.syncError(
                    errorText: LocaleKeys.signIn_invalidLoginCredentials.tr(),
                  );
                });
              } else if (state.passwordError != null) {
                inputPasswordKey.currentState?.syncError(
                  errorText: LocaleKeys.signIn_invalidLoginCredentials.tr(),
                );
              } else {
                inputPasswordKey.currentState?.clearError();
              }

              if (isSubmitting != state.isSubmitting) {
                setState(() {
                  isSubmitting = state.isSubmitting;
                });
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and title
                _buildLogoAndTitle(),

                // Password input and buttons
                ..._buildPasswordSection(),

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

  Widget _buildLogoAndTitle() {
    return TitleLogo(
      title: 'Reset password',
      description: 'Enter your email to reset your password',
    );
  }

  List<Widget> _buildPasswordSection() {
    final theme = AppFlowyTheme.of(context);
    final iconSize = 20.0;

    return [
      // Password input
      AFTextField(
        key: inputPasswordKey,
        controller: passwordController,
        hintText: LocaleKeys.signIn_enterPassword.tr(),
        autoFocus: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        onSubmitted: (_) => _onSubmit(),
      ),

      VSpace(theme.spacing.xxl),

      // Continue button
      isSubmitting
          ? const VerifyingButton()
          : ContinueWithButton(
              text: 'Submit',
              onTap: _onSubmit,
            ),
      VSpace(theme.spacing.xxl),
    ];
  }

  Future<void> _onSubmit() async {
    final email = passwordController.text;
    if (!isEmail(email)) {
      inputPasswordKey.currentState?.syncError(
        errorText: LocaleKeys.signIn_invalidEmail.tr(),
      );
      return;
    }

    final signInBloc = context.read<SignInBloc>();

    setState(() {
      isSubmitting = true;
    });

    final result = await forgotPasswordService.forgotPassword(email: email);

    setState(() {
      isSubmitting = false;
    });

    result.fold(
      (success) {
        // push the email to the next screen
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/reset-password'),
            builder: (context) => BlocProvider.value(
              value: signInBloc,
              child: ResetPasswordPage(
                email: email,
                backToLogin: widget.backToLogin,
                baseUrl: widget.baseUrl,
              ),
            ),
          ),
        );
      },
      (error) {
        inputPasswordKey.currentState?.syncError(
          errorText: error.toString(),
        );
      },
    );
  }
}
