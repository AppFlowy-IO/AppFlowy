import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// Menu item widget
class AFMenuItem extends StatelessWidget {
  /// Creates a menu item.
  ///
  /// [title] and [onTap] are required. Optionally provide [leading], [subtitle], [selected], and [trailing].
  const AFMenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.selected = false,
    this.trailing,
  });

  /// Widget to display before the title (e.g., an icon or avatar).
  final Widget? leading;

  /// The main text of the menu item.
  final String title;

  /// Optional secondary text displayed below the title.
  final String? subtitle;

  /// Whether the menu item is selected.
  final bool selected;

  /// Called when the menu item is tapped.
  final VoidCallback onTap;

  /// Widget to display after the title (e.g., a trailing icon).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFBaseButton(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      borderRadius: theme.borderRadius.m,
      borderColor: (context, isHovering, disabled, isFocused) {
        return theme.borderColorScheme.transparent;
      },
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.transparent;
        }
        if (selected) {
          return theme.fillColorScheme.themeSelect;
        }
        if (isHovering) {
          return theme.fillColorScheme.primaryAlpha5;
        }
        return theme.fillColorScheme.transparent;
      },
      builder: (context, isHovering, disabled) {
        return Row(
          children: [
            // Leading widget (icon/avatar), if provided
            if (leading != null) ...[
              leading!,
              SizedBox(width: theme.spacing.m),
            ],
            // Main content: title and optional subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title text
                  Text(
                    title,
                    style: theme.textStyle.body.standard(
                      color: theme.textColorScheme.primary,
                    ),
                  ),
                  // Subtitle text, if provided
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textStyle.caption.standard(
                        color: theme.textColorScheme.secondary,
                      ),
                    ),
                ],
              ),
            ),
            // Trailing widget (e.g., icon), if provided
            if (trailing != null) trailing!,
          ],
        );
      },
    );
  }
}
