import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/logo/logo.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/password/password_suffix_icon.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
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
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final passwordController = TextEditingController();
  final inputPasswordKey = GlobalKey<AFTextFieldState>();

  bool isSubmitting = false;

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
        LocaleKeys.signIn_enterPassword.tr(),
        style: theme.textStyle.heading3.enhanced(
          color: theme.textColorScheme.primary,
        ),
      ),
      spacing,

      // email display
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: LocaleKeys.signIn_loginAs.tr(),
              style: theme.textStyle.body.standard(
                color: theme.textColorScheme.primary,
              ),
            ),
            TextSpan(
              text: ' ${widget.email}',
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
    final theme = AppFlowyTheme.of(context);
    final iconSize = 20.0;
    final textStyle = AFButtonSize.l.buildTextStyle(context);
    final textHeight = textStyle.height;
    final textFontSize = textStyle.fontSize;

    // the indicator height is the height of the text style.
    double indicatorHeight = 20;
    if (textHeight != null && textFontSize != null) {
      indicatorHeight = textHeight * textFontSize;
    }

    return [
      // Password input
      AFTextField(
        key: inputPasswordKey,
        controller: passwordController,
        hintText: LocaleKeys.signIn_enterPassword.tr(),
        autoFocus: true,
        obscureText: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        suffixIconBuilder: (context, isObscured) => PasswordSuffixIcon(
          isObscured: isObscured,
          onTap: () {
            inputPasswordKey.currentState?.syncObscured(!isObscured);
          },
        ),
        onSubmitted: widget.onEnterPassword,
      ),
      // todo: ask designer to provide the spacing
      VSpace(8),

      // Forgot password button
      Align(
        alignment: Alignment.centerLeft,
        child: AFGhostTextButton(
          text: LocaleKeys.signIn_forgotPassword.tr(),
          size: AFButtonSize.s,
          padding: EdgeInsets.zero,
          onTap: widget.onForgotPassword,
          textStyle: theme.textStyle.body.standard(
            color: theme.textColorScheme.action,
          ),
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
      isSubmitting
          ? _buildIndicator(indicatorHeight: indicatorHeight)
          : _buildContinueButton(textStyle: textStyle),
      VSpace(20),
    ];
  }

  Widget _buildContinueButton({
    required TextStyle textStyle,
  }) {
    return AFFilledTextButton.primary(
      text: LocaleKeys.web_continue.tr(),
      textStyle: textStyle.copyWith(
        color: AppFlowyTheme.of(context).textColorScheme.onFill,
      ),
      onTap: () => widget.onEnterPassword(passwordController.text),
      size: AFButtonSize.l,
      alignment: Alignment.center,
    );
  }

  Widget _buildIndicator({
    required double indicatorHeight,
  }) {
    return AFFilledButton.disabled(
      size: AFButtonSize.l,
      builder: (context, isHovering, disabled) {
        return Align(
          child: SizedBox.square(
            dimension: indicatorHeight,
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildBackToLogin() {
    return [
      AFGhostTextButton(
        text: LocaleKeys.signIn_backToLogin.tr(),
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
