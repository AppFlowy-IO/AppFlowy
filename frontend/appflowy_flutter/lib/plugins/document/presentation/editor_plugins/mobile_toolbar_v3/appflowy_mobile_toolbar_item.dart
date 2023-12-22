import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/appflowy_mobile_toolbar.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

// build the toolbar item, like Aa, +, image ...
typedef AppFlowyMobileToolbarItemBuilder = Widget Function(
  BuildContext context,
  EditorState editorState,
  AppFlowyMobileToolbarWidgetService service,
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
    this.pilotAtCollapsedSelection = false,
    this.pilotAtExpandedSelection = false,
  });

  final AppFlowyMobileToolbarItemBuilder itemBuilder;
  final AppFlowyMobileToolbarItemMenuBuilder? menuBuilder;
  final bool pilotAtCollapsedSelection;
  final bool pilotAtExpandedSelection;
}

class AppFlowyMobileToolbarIconItem extends StatefulWidget {
  const AppFlowyMobileToolbarIconItem({
    super.key,
    this.icon,
    this.keepSelectedStatus = false,
    this.iconBuilder,
    this.isSelected,
    required this.onTap,
  });

  final FlowySvgData? icon;
  final bool keepSelectedStatus;
  final VoidCallback onTap;
  final WidgetBuilder? iconBuilder;
  final bool Function()? isSelected;

  @override
  State<AppFlowyMobileToolbarIconItem> createState() =>
      _AppFlowyMobileToolbarIconItemState();
}

class _AppFlowyMobileToolbarIconItemState
    extends State<AppFlowyMobileToolbarIconItem> {
  bool isSelected = false;

  @override
  void initState() {
    super.initState();

    isSelected = widget.isSelected?.call() ?? false;
  }

  @override
  void didUpdateWidget(covariant AppFlowyMobileToolbarIconItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != null) {
      isSelected = widget.isSelected!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onTap();
          if (widget.keepSelectedStatus && widget.isSelected == null) {
            setState(() {
              isSelected = !isSelected;
            });
          } else {
            setState(() {
              isSelected = widget.isSelected?.call() ?? false;
            });
          }
        },
        child: Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? const Color(0x1f232914) : null,
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
