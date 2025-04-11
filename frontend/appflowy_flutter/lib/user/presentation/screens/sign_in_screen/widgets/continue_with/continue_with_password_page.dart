import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/logo/logo.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContinueWithPasswordPage extends StatefulWidget {
  const ContinueWithPasswordPage({
    super.key,
    required this.backToLogin,
    required this.email,
    required this.onEnterPassword,
    required this.onForgotPassword,
  });

  final String email;
  final VoidCallback backToLogin;
  final ValueChanged<String> onEnterPassword;
  final VoidCallback onForgotPassword;

  @override
  State<ContinueWithPasswordPage> createState() =>
      _ContinueWithPasswordPageState();
}

class _ContinueWithPasswordPageState extends State<ContinueWithPasswordPage> {
  final passwordController = TextEditingController();
  final inputPasswordKey = GlobalKey<AFTextFieldState>();

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
              if (state.passwordError != null) {
                inputPasswordKey.currentState?.syncError(
                  hasError: true,
                  errorText: 'Incorrect password. Please try again.',
                );
              } else {
                inputPasswordKey.currentState?.syncError();
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and title
                ..._buildLogoAndTitle(),

                // Password input and buttons
                ..._buildPasswordSection(),

                // Back to login
                ..._buildBackToLogin(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLogoAndTitle() {
    final theme = AppFlowyTheme.of(context);
    final spacing = VSpace(theme.spacing.xxl);
    return [
      // logo
      const AFLogo(),
      spacing,

      // title
      Text(
        'Enter password',
        style: theme.textStyle.heading.h3(
          color: theme.textColorScheme.primary,
        ),
      ),
      spacing,

      // email display
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Login as ',
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
      ),
      spacing,
    ];
  }

  List<Widget> _buildPasswordSection() {
    return [
      // Password input
      AFTextField(
        key: inputPasswordKey,
        controller: passwordController,
        hintText: 'Enter password',
        autoFocus: true,
        onSubmitted: widget.onEnterPassword,
      ),
      // todo: ask designer to provide the spacing
      VSpace(8),

      // Forgot password button
      Align(
        alignment: Alignment.centerLeft,
        child: AFGhostTextButton(
          text: 'Forget password?',
          size: AFButtonSize.s,
          padding: EdgeInsets.zero,
          onTap: widget.onForgotPassword,
          textColor: (context, isHovering, disabled) {
            final theme = AppFlowyTheme.of(context);
            if (isHovering) {
              return theme.fillColorScheme.themeThickHover;
            }
            return theme.textColorScheme.theme;
          },
        ),
      ),
      VSpace(20),

      // Continue button
      AFFilledTextButton.primary(
        text: 'Continue',
        onTap: () => widget.onEnterPassword(passwordController.text),
        size: AFButtonSize.l,
        alignment: Alignment.center,
      ),
      VSpace(20),
    ];
  }

  List<Widget> _buildBackToLogin() {
    return [
      AFGhostTextButton(
        text: 'Back to Login',
        size: AFButtonSize.s,
        onTap: widget.backToLogin,
        padding: EdgeInsets.zero,
        textColor: (context, isHovering, disabled) {
          final theme = AppFlowyTheme.of(context);
          if (isHovering) {
            return theme.fillColorScheme.themeThickHover;
          }
          return theme.textColorScheme.theme;
        },
      ),
    ];
  }
}
