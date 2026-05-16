import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';

class PopupMenuItemWrapper extends StatelessWidget {
  const PopupMenuItemWrapper({
    super.key,
    required this.isSelected,
    required this.icon,
  });

  final bool isSelected;
  final FlowySvgData icon;

  @override
  Widget build(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    return Container(
      width: 62,
      height: 44,
      decoration: ShapeDecoration(
        color: isSelected ? theme.toolbarMenuItemSelectedBackgroundColor : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: FlowySvg(
        icon,
        color: isSelected
            ? theme.toolbarMenuIconSelectedColor
            : theme.toolbarMenuIconColor,
      ),
    );
  }
}

class PopupMenuWrapper extends StatelessWidget {
  const PopupMenuWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: ShapeDecoration(
        color: theme.toolbarMenuBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: [
          BoxShadow(
            color: theme.toolbarShadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
