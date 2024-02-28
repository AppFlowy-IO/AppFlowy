import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_toolbar_theme.dart';
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
    this.shouldListenToToggledStyle = false,
    required this.onTap,
    required this.editorState,
  });

  final FlowySvgData? icon;
  final bool keepSelectedStatus;
  final VoidCallback onTap;
  final WidgetBuilder? iconBuilder;
  final bool Function()? isSelected;
  final bool shouldListenToToggledStyle;
  final EditorState editorState;

  @override
  State<AppFlowyMobileToolbarIconItem> createState() =>
      _AppFlowyMobileToolbarIconItemState();
}

class _AppFlowyMobileToolbarIconItemState
    extends State<AppFlowyMobileToolbarIconItem> {
  bool isSelected = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    isSelected = widget.isSelected?.call() ?? false;
    if (widget.shouldListenToToggledStyle) {
      widget.editorState.toggledStyleNotifier.addListener(_rebuild);
      _subscription = widget.editorState.transactionStream.listen((_) {
        _rebuild();
      });
    }
  }

  @override
  void dispose() {
    if (widget.shouldListenToToggledStyle) {
      widget.editorState.toggledStyleNotifier.removeListener(_rebuild);
      _subscription?.cancel();
    }
    super.dispose();
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
    final theme = ToolbarColorExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onTap();
          _rebuild();
        },
        child: Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? theme.toolbarItemSelectedBackgroundColor : null,
          ),
          child: widget.iconBuilder?.call(context) ??
              FlowySvg(
                widget.icon!,
                color: theme.toolbarItemIconColor,
              ),
        ),
      ),
    );
  }

  void _rebuild() {
    setState(() {
      isSelected = (widget.keepSelectedStatus && widget.isSelected == null)
          ? !isSelected
          : widget.isSelected?.call() ?? false;
    });
  }
}
