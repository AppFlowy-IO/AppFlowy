import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// This is used to create a uniform space and divider
/// between categories in settings.
///
class SettingsCategorySpacer extends StatelessWidget {
  const SettingsCategorySpacer({
    super.key,
    this.topSpacing,
    this.bottomSpacing,
  });

  final double? topSpacing;
  final double? bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: topSpacing ?? theme.spacing.l,
        bottom: bottomSpacing ?? theme.spacing.l,
      ),
      child: Divider(
        color: theme.borderColorScheme.primary,
      ),
    );
  }
}
