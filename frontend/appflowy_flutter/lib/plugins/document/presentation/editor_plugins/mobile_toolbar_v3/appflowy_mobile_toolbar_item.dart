import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

// build the toolbar item, like Aa, +, image ...
typedef AppFlowyMobileToolbarItemBuilder = Widget Function(
  BuildContext context,
  EditorState editorState,
  VoidCallback? onMenuCallback,
  VoidCallback? onActionCallback,
);

// build the menu after clicking the toolbar item
typedef AppFlowyMobileToolbarItemMenuBuilder = Widget Function(
  BuildContext context,
  EditorState editorState,
  MobileToolbarWidgetService service,
);

class AppFlowyMobileToolbarItem {
  /// Tool bar item that implements attribute directly(without opening menu)
  const AppFlowyMobileToolbarItem({
    required this.itemBuilder,
    this.menuBuilder,
  });

  final AppFlowyMobileToolbarItemBuilder itemBuilder;
  final AppFlowyMobileToolbarItemMenuBuilder? menuBuilder;
}

class AppFlowyMobileToolbarIconItem extends StatefulWidget {
  const AppFlowyMobileToolbarIconItem({
    super.key,
    required this.icon,
    this.keepSelectedStatus = false,
    required this.onTap,
  });

  final FlowySvgData icon;
  final bool keepSelectedStatus;
  final VoidCallback onTap;

  @override
  State<AppFlowyMobileToolbarIconItem> createState() =>
      _AppFlowyMobileToolbarIconItemState();
}

class _AppFlowyMobileToolbarIconItemState
    extends State<AppFlowyMobileToolbarIconItem> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.keepSelectedStatus) {
            setState(() {
              isSelected = !isSelected;
            });
          }

          widget.onTap();
        },
        child: Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isSelected ? Colors.blue.withOpacity(0.5) : null,
          ),
          child: FlowySvg(
            widget.icon,
          ),
        ),
      ),
    );
  }
}
