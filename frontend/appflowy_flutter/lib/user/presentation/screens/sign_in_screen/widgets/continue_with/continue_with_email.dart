import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ContinueWithEmail extends StatelessWidget {
  const ContinueWithEmail({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AFFilledTextButton.primary(
      text: LocaleKeys.signIn_continueWithEmail.tr(),
      size: AFButtonSize.l,
      alignment: Alignment.center,
      onTap: onTap,
    );
  }
}
