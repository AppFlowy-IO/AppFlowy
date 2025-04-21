import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// This is used to create a uniform space and divider
/// between categories in settings.
///
class SettingsCategorySpacer extends StatelessWidget {
  const SettingsCategorySpacer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Divider(
      height: 32,
      color: theme.borderColorScheme.greyPrimary,
    );
  }
}
