import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/logo/logo.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class ContinueWithMagicLinkOrPasscode extends StatefulWidget {
  const ContinueWithMagicLinkOrPasscode({
    super.key,
    required this.backToLogin,
    required this.email,
  });

  final VoidCallback backToLogin;
  final String email;

  @override
  State<ContinueWithMagicLinkOrPasscode> createState() =>
      _ContinueWithMagicLinkOrPasscodeState();
}

class _ContinueWithMagicLinkOrPasscodeState
    extends State<ContinueWithMagicLinkOrPasscode> {
  bool isEnteringPasscode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._buildLogoTitleAndDescription(),

              // Enter code manually
              ..._buildEnterCodeManually(),

              // Back to login
              ..._buildBackToLogin(),
            ],
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
          text: 'Enter code manually',
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
        height: 40, // fixme: use the height from the designer
        child: AFTextField(
          hintText: 'Enter code',
          keyboardType: TextInputType.number,
          radius: 10,
          autoFocus: true,
        ),
      ),
      // todo: ask designer to provide the spacing
      VSpace(12),

      // continue to login
      AFFilledTextButton.primary(
        text: 'Continue to sign up',
        onTap: () {},
        size: AFButtonSize.l,
        alignment: Alignment.center,
      ),

      spacing,
    ];
  }

  List<Widget> _buildBackToLogin() {
    return [
      AFGhostTextButton(
        text: 'Back to login',
        size: AFButtonSize.s,
        onTap: widget.backToLogin,
        textColor: (context, isHovering, disabled) {
          final theme = AppFlowyTheme.of(context);
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
        'Check your email',
        style: theme.textStyle.heading.h3(
          color: theme.textColorScheme.primary,
        ),
      ),
      spacing,

      // description
      Text(
        'A temporary verification link has been sent. Please check your inbox at',
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
