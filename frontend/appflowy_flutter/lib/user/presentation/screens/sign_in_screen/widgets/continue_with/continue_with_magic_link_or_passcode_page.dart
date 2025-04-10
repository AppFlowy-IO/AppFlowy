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

  @override
  void dispose() {
    passcodeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        if (state.isSubmitting) {
          _showLoadingDialog();
        } else {
          _dismissLoadingDialog();
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
      SizedBox(
        height: 40,
        child: AFTextField(
          controller: passcodeController,
          hintText: LocaleKeys.signIn_enterCode.tr(),
          keyboardType: TextInputType.number,
          radius: 10,
          autoFocus: true,
          onSubmitted: widget.onEnterPasscode,
        ),
      ),
      // todo: ask designer to provide the spacing
      VSpace(12),

      // continue to login
      AFFilledTextButton.primary(
        text: 'Continue to sign in',
        onTap: () => widget.onEnterPasscode(passcodeController.text),
        size: AFButtonSize.l,
        alignment: Alignment.center,
      ),

      spacing,
    ];
  }

  List<Widget> _buildBackToLogin() {
    return [
      AFGhostTextButton(
        text: LocaleKeys.signIn_backToLogin.tr(),
        size: AFButtonSize.s,
        onTap: widget.backToLogin,
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
    return [
      // logo
      const AFLogo(),
      spacing,

      // title
      Text(
        LocaleKeys.signIn_checkYourEmail.tr(),
        style: theme.textStyle.heading.h3(
          color: theme.textColorScheme.primary,
        ),
      ),
      spacing,

      // description
      Text(
        LocaleKeys.signIn_temporaryVerificationSent.tr(),
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

  void _showLoadingDialog() {
    _dismissLoadingDialog();

    toastificationItem = showToastNotification(
      context,
      message: LocaleKeys.signIn_signingIn.tr(),
    );
  }

  void _dismissLoadingDialog() {
    final toastificationItem = this.toastificationItem;
    if (toastificationItem != null) {
      toastification.dismiss(toastificationItem);
    }
  }
}
