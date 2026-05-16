import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
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
    this.enable,
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
  final bool Function()? enable;

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
    final enable = widget.enable?.call() ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: AnimatedGestureDetector(
        scaleFactor: 0.95,
        onTapUp: () {
          widget.onTap();
          _rebuild();
        },
        child: widget.iconBuilder?.call(context) ??
            Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: isSelected
                    ? theme.toolbarItemSelectedBackgroundColor
                    : null,
              ),
              child: FlowySvg(
                widget.icon!,
                color: enable
                    ? theme.toolbarItemIconColor
                    : theme.toolbarItemIconDisabledColor,
              ),
            ),
      ),
    );
  }

  void _rebuild() {
    if (!mounted) {
      return;
    }
    setState(() {
      isSelected = (widget.keepSelectedStatus && widget.isSelected == null)
          ? !isSelected
          : widget.isSelected?.call() ?? false;
    });
  }
}
