import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RefreshSharedSectionButton extends StatelessWidget {
  const RefreshSharedSectionButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFTextMenuItem(
      leading: Icon(
        Icons.refresh,
        size: 20,
        color: theme.iconColorScheme.secondary,
      ),
      title: LocaleKeys.shareSection_refresh.tr(),
      onTap: onTap,
    );
  }
}
