import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum ThirdPartySignInButtonType {
  apple,
  google,
  github,
  discord,
  anonymous;

  FlowySvgData get icon {
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return FlowySvgs.m_apple_icon_xl;
      case ThirdPartySignInButtonType.google:
        return FlowySvgs.m_google_icon_xl;
      case ThirdPartySignInButtonType.github:
        return FlowySvgs.m_github_icon_xl;
      case ThirdPartySignInButtonType.discord:
        return FlowySvgs.m_discord_icon_xl;
      case ThirdPartySignInButtonType.anonymous:
        return FlowySvgs.m_discord_icon_xl;
    }
  }

  String get labelText {
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return LocaleKeys.signIn_signInWithApple.tr();
      case ThirdPartySignInButtonType.google:
        return LocaleKeys.signIn_signInWithGoogle.tr();
      case ThirdPartySignInButtonType.github:
        return LocaleKeys.signIn_signInWithGithub.tr();
      case ThirdPartySignInButtonType.discord:
        return LocaleKeys.signIn_signInWithDiscord.tr();
      case ThirdPartySignInButtonType.anonymous:
        return 'Anonymous session';
    }
  }

  // https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
  Color backgroundColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return isDarkMode ? Colors.white : Colors.black;
      case ThirdPartySignInButtonType.google:
      case ThirdPartySignInButtonType.github:
      case ThirdPartySignInButtonType.discord:
      case ThirdPartySignInButtonType.anonymous:
        return isDarkMode ? Colors.black : Colors.grey.shade100;
    }
  }

  Color textColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return isDarkMode ? Colors.black : Colors.white;
      case ThirdPartySignInButtonType.google:
      case ThirdPartySignInButtonType.github:
      case ThirdPartySignInButtonType.discord:
      case ThirdPartySignInButtonType.anonymous:
        return isDarkMode ? Colors.white : Colors.black;
    }
  }

  BlendMode? get blendMode {
    switch (this) {
      case ThirdPartySignInButtonType.apple:
      case ThirdPartySignInButtonType.github:
        return BlendMode.srcIn;
      default:
        return null;
    }
  }
}

class MobileThirdPartySignInButton extends StatelessWidget {
  const MobileThirdPartySignInButton({
    super.key,
    this.height = 38,
    this.fontSize = 14.0,
    required this.onPressed,
    required this.type,
  });

  final VoidCallback onPressed;
  final double height;
  final double fontSize;
  final ThirdPartySignInButtonType type;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    return AnimatedGestureDetector(
      scaleFactor: 1.0,
      onTapUp: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: type.backgroundColor(context),
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          ),
          border: Border.all(
            color: style.colorScheme.outline,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (type != ThirdPartySignInButtonType.anonymous)
              FlowySvg(
                type.icon,
                size: Size.square(fontSize),
                blendMode: type.blendMode,
                color: type.textColor(context),
              ),
            const HSpace(8.0),
            FlowyText(
              type.labelText,
              fontSize: fontSize,
              color: type.textColor(context),
            ),
          ],
        ),
      ),
    );
  }
}
