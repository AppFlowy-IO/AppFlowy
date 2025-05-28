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
    this.onTap,
    this.leading,
    this.subtitle,
    this.selected = false,
    this.trailing,
    this.padding,
    this.showSelectedBackground = true,
  });

  /// Widget to display before the title (e.g., an icon or avatar).
  final Widget? leading;

  /// The main text of the menu item.
  final Widget title;

  /// Optional secondary text displayed below the title.
  final Widget? subtitle;

  /// Whether the menu item is selected.
  final bool selected;

  /// Whether to show the selected background color.
  final bool showSelectedBackground;

  /// Called when the menu item is tapped.
  final VoidCallback? onTap;

  /// Widget to display after the title (e.g., a trailing icon).
  final Widget? trailing;

  /// Padding of the menu item.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        );

    return AFBaseButton(
      onTap: onTap,
      padding: effectivePadding,
      borderRadius: theme.borderRadius.m,
      borderColor: (context, isHovering, disabled, isFocused) {
        return Colors.transparent;
      },
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.content;
        }
        if (selected && showSelectedBackground) {
          return theme.fillColorScheme.themeSelect;
        }
        if (isHovering && onTap != null) {
          return theme.fillColorScheme.contentHover;
        }
        return theme.fillColorScheme.content;
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
                  title,
                  // Subtitle text, if provided
                  if (subtitle != null) subtitle!,
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
