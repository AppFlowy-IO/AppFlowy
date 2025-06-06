import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class HoverMenu extends StatefulWidget {
  const HoverMenu({
    super.key,
    required this.menuConstraints,
    required this.triggerSize,
    required this.child,
    required this.menuBuilder,
    this.delayToShow = const Duration(milliseconds: 50),
    this.delayToHide = const Duration(milliseconds: 300),
  });

  final BoxConstraints menuConstraints;
  final Size triggerSize;
  final Widget child;
  final WidgetBuilder menuBuilder;
  final Duration delayToShow;
  final Duration delayToHide;

  @override
  State<HoverMenu> createState() => _HoverMenuState();
}

class _HoverMenuState extends State<HoverMenu> {
  final controller = PopoverController();
  bool isHoverMenuShowing = false;
  bool isHovering = false;

  BoxConstraints get menuConstraints => widget.menuConstraints;
  Size get triggerSize => widget.triggerSize;

  @override
  Widget build(BuildContext context) {
    return buildHoverMouseRegion(
      buildPopover(),
      cursor: SystemMouseCursors.click,
    );
  }

  Widget buildPopover() {
    return AppFlowyPopover(
      controller: controller,
      direction: PopoverDirection.topWithLeftAligned,
      offset: Offset(0, triggerSize.height),
      onOpen: () {
        keepEditorFocusNotifier.increase();
        isHoverMenuShowing = true;
      },
      onClose: () {
        keepEditorFocusNotifier.decrease();
        isHoverMenuShowing = false;
      },
      margin: EdgeInsets.zero,
      constraints: menuConstraints.copyWith(
        maxHeight: menuConstraints.maxHeight + triggerSize.height,
      ),
      decorationColor: Colors.transparent,
      popoverDecoration: BoxDecoration(),
      popupBuilder: (context) =>
          buildHoverMouseRegion(widget.menuBuilder.call(context)),
      child: widget.child,
    );
  }

  Widget buildHoverMouseRegion(
    Widget child, {
    MouseCursor cursor = MouseCursor.defer,
  }) {
    return MouseRegion(
      cursor: cursor,
      onEnter: (e) => onEnter(),
      onExit: (e) => onExit(),
      child: child,
    );
  }

  void onEnter() {
    isHovering = true;
    Future.delayed(widget.delayToShow, () {
      if (isHovering && !isHoverMenuShowing) {
        showHoverMenu();
      }
    });
  }

  void onExit() {
    isHovering = false;
    tryToDismissenu();
  }

  void showHoverMenu() {
    if (isHoverMenuShowing || !mounted) {
      return;
    }
    keepEditorFocusNotifier.increase();
    controller.show();
  }

  void tryToDismissenu() {
    Future.delayed(widget.delayToHide, () {
      if (isHovering) return;
      keepEditorFocusNotifier.increase();
      controller.close();
    });
  }
}
