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
    this.builder,
    this.backgroundColor,
  });

  /// The list of widgets to display in the menu (sections or menu items).
  final List<Widget> children;

  /// The width of the menu.
  final double? width;

  /// An optional builder to customize the children of the menu
  final AFMenuChildrenBuilder? builder;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.surfaceColorScheme.primary,
        borderRadius: BorderRadius.circular(theme.borderRadius.l),
        border: Border.all(
          color: theme.borderColorScheme.primary,
        ),
        boxShadow: theme.shadow.medium,
      ),
      width: width,
      padding: EdgeInsets.all(theme.spacing.m),
      child: builder?.call(context, children) ??
          Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
    );
  }
}

typedef AFMenuChildrenBuilder = Widget Function(
  BuildContext context,
  List<Widget> children,
);
