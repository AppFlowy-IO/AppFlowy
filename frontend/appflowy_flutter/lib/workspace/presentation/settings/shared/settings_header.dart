import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

/// Renders a simple header for the settings view
///
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textStyle.heading2.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        if (description?.isNotEmpty == true) ...[
          const VSpace(8),
          FlowyText(
            description!,
            maxLines: 4,
            fontSize: 12,
            color: AFThemeExtension.of(context).secondaryTextColor,
          ),
        ],
        const VSpace(16),
      ],
    );
  }
}
