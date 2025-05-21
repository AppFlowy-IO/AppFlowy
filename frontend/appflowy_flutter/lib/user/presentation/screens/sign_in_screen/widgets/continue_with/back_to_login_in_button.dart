import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BackToLoginButton extends StatelessWidget {
  const BackToLoginButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AFGhostTextButton(
      text: LocaleKeys.signIn_backToLogin.tr(),
      size: AFButtonSize.s,
      onTap: onTap,
      padding: EdgeInsets.zero,
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (isHovering) {
          return theme.textColorScheme.actionHover;
        }
        return theme.textColorScheme.action;
      },
    );
  }
}
