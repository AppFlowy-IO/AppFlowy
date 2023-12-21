import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/appflowy_mobile_toolbar.dart';
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
  AppFlowyMobileToolbarWidgetService service,
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
    this.icon,
    this.keepSelectedStatus = false,
    this.iconBuilder,
    required this.onTap,
  });

  final FlowySvgData? icon;
  final bool keepSelectedStatus;
  final VoidCallback onTap;
  final WidgetBuilder? iconBuilder;

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
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isSelected ? Colors.blue.withOpacity(0.5) : null,
          ),
          child: widget.iconBuilder?.call(context) ??
              FlowySvg(
                widget.icon!,
              ),
        ),
      ),
    );
  }
}
