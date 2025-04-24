import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/logo/logo.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContinueWithMagicLinkOrPasscodePage extends StatefulWidget {
  const ContinueWithMagicLinkOrPasscodePage({
    super.key,
    required this.backToLogin,
    required this.email,
    required this.onEnterPasscode,
  });

  final String email;
  final VoidCallback backToLogin;
  final ValueChanged<String> onEnterPasscode;

  @override
  State<ContinueWithMagicLinkOrPasscodePage> createState() =>
      _ContinueWithMagicLinkOrPasscodePageState();
}

class _ContinueWithMagicLinkOrPasscodePageState
    extends State<ContinueWithMagicLinkOrPasscodePage> {
  final passcodeController = TextEditingController();

  bool isEnteringPasscode = false;

  ToastificationItem? toastificationItem;

  final inputPasscodeKey = GlobalKey<AFTextFieldState>();

  bool isSubmitting = false;

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
                ..._buildLogoTitleAndDescription(),

                // Enter code manually
                ..._buildEnterCodeManually(),

                // Back to login
                ..._buildBackToLogin(),
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
    final textStyle = AFButtonSize.l.buildTextStyle(context);

    if (!isEnteringPasscode) {
      return [
        AFFilledTextButton.primary(
          text: LocaleKeys.signIn_enterCodeManually.tr(),
          onTap: () => setState(() => isEnteringPasscode = true),
          size: AFButtonSize.l,
          alignment: Alignment.center,
        ),
        spacing,
      ];
    }

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
            widget.onEnterPasscode(passcode);
          }
        },
      ),
      // todo: ask designer to provide the spacing
      VSpace(12),

      // continue to login
      isSubmitting
          ? _buildIndicator(textStyle: textStyle)
          : _buildContinueButton(textStyle: textStyle),

      spacing,
    ];
  }

  Widget _buildContinueButton({
    required TextStyle textStyle,
  }) {
    return AFFilledTextButton.primary(
      text: LocaleKeys.signIn_continueToSignIn.tr(),
      onTap: () {
        final passcode = passcodeController.text;
        if (passcode.isEmpty) {
          inputPasscodeKey.currentState?.syncError(
            errorText: LocaleKeys.signIn_invalidVerificationCode.tr(),
          );
        } else {
          widget.onEnterPasscode(passcode);
        }
      },
      textStyle: textStyle.copyWith(
        color: AppFlowyTheme.of(context).textColorScheme.onFill,
      ),
      size: AFButtonSize.l,
      alignment: Alignment.center,
    );
  }

  Widget _buildIndicator({
    required TextStyle textStyle,
  }) {
    final theme = AppFlowyTheme.of(context);
    return Opacity(
      opacity: 0.7, // TODO: ask designer to provide the opacity
      child: AFFilledButton.disabled(
        size: AFButtonSize.l,
        backgroundColor: theme.fillColorScheme.themeThick,
        builder: (context, isHovering, disabled) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 15.0,
                child: CircularProgressIndicator(
                  color: theme.textColorScheme.onFill,
                  strokeWidth: 3.0,
                ),
              ),
              HSpace(theme.spacing.l),
              Text(
                'Verifying...',
                style: textStyle.copyWith(
                  color: theme.textColorScheme.onFill,
                ),
              ),
            ],
          );
        },
      ),
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

  List<Widget> _buildLogoTitleAndDescription() {
    final theme = AppFlowyTheme.of(context);
    final spacing = VSpace(theme.spacing.xxl);
    if (!isEnteringPasscode) {
      return [
        // logo
        const AFLogo(),
        spacing,

        // title
        Text(
          LocaleKeys.signIn_checkYourEmail.tr(),
          style: theme.textStyle.heading3.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        spacing,

        // description
        Text(
          LocaleKeys.signIn_temporaryVerificationLinkSent.tr(),
          style: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          widget.email,
          style: theme.textStyle.body.enhanced(
            color: theme.textColorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        spacing,
      ];
    } else {
      return [
        // logo
        const AFLogo(),
        spacing,

        // title
        Text(
          LocaleKeys.signIn_enterCode.tr(),
          style: theme.textStyle.heading3.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        spacing,

        // description
        Text(
          LocaleKeys.signIn_temporaryVerificationCodeSent.tr(),
          style: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          widget.email,
          style: theme.textStyle.body.enhanced(
            color: theme.textColorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        spacing,
      ];
    }
  }
}
