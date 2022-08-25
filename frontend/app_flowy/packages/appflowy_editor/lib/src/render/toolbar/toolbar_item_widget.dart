import 'package:flutter/material.dart';

import 'toolbar_item.dart';

class ToolbarItemWidget extends StatelessWidget {
  const ToolbarItemWidget({
    Key? key,
    required this.item,
    required this.onPressed,
  }) : super(key: key);

  final ToolbarItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Tooltip(
        preferBelow: false,
        message: item.tooltipsMessage,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: item.icon,
            iconSize: 28,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
