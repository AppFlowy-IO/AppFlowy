import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// Text menu item widget
class AFTextMenuItem extends StatelessWidget {
  /// Creates a text menu item.
  ///
  /// [title] and [onTap] are required. Optionally provide [leading], [subtitle], [selected], and [trailing].
  const AFTextMenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.selected = false,
    this.trailing,
    this.titleColor,
    this.subtitleColor,
    this.showSelectedBackground = true,
  });

  /// Widget to display before the title (e.g., an icon or avatar).
  final Widget? leading;

  /// The main text of the menu item.
  final String title;

  /// The color of the title.
  final Color? titleColor;

  /// Optional secondary text displayed below the title.
  final String? subtitle;

  /// The color of the subtitle.
  final Color? subtitleColor;

  /// Whether the menu item is selected.
  final bool selected;

  /// Whether to show the selected background color.
  final bool showSelectedBackground;

  /// Called when the menu item is tapped.
  final VoidCallback onTap;

  /// Widget to display after the title (e.g., a trailing icon).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFMenuItem(
      title: Text(
        title,
        style: theme.textStyle.body.standard(
          color: titleColor ?? theme.textColorScheme.primary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textStyle.caption.standard(
                color: subtitleColor ?? theme.textColorScheme.secondary,
              ),
            )
          : null,
      leading: leading,
      trailing: trailing,
      selected: selected,
      showSelectedBackground: showSelectedBackground,
      onTap: onTap,
    );
  }
}
