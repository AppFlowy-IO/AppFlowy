import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class GuestTag extends StatelessWidget {
  const GuestTag({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
      ),
      decoration: BoxDecoration(
        color: theme.fillColorScheme.warningLight,
        borderRadius: BorderRadius.circular(theme.spacing.s),
      ),
      child: Text(
        LocaleKeys.shareTab_guest.tr(),
        style: theme.textStyle.caption.standard(
          color: theme.textColorScheme.warning,
        ),
      ),
    );
  }
}
