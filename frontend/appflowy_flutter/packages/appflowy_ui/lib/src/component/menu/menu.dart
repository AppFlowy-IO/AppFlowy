import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

export 'menu_item.dart';
export 'section.dart';
export 'text_menu_item.dart';

/// The main menu container widget, supporting sections, menu items.
class AFMenu extends StatelessWidget {
  const AFMenu({
    super.key,
    required this.children,
    this.width,
  });

  /// The list of widgets to display in the menu (sections or menu items).
  final List<Widget> children;

  /// The width of the menu.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColorScheme.primary,
        borderRadius: BorderRadius.circular(theme.borderRadius.l),
        border: Border.all(
          color: theme.borderColorScheme.primary,
        ),
        boxShadow: theme.shadow.medium,
      ),
      width: width,
      padding: EdgeInsets.all(theme.spacing.m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
