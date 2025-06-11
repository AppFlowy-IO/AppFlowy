import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoverMenu extends StatefulWidget {
  const HoverMenu({
    super.key,
    required this.menuConstraints,
    required this.triggerSize,
    required this.child,
    required this.menuBuilder,
    this.delayToShow = const Duration(milliseconds: 50),
    this.delayToHide = const Duration(milliseconds: 300),
    this.direction = PopoverDirection.topWithLeftAligned,
    this.offset = Offset.zero,
    this.enable = true,
    this.onEnter,
    this.onExit,
  });

  final BoxConstraints menuConstraints;
  final Size triggerSize;
  final Widget child;
  final WidgetBuilder menuBuilder;
  final Duration delayToShow;
  final Duration delayToHide;
  final PopoverDirection direction;
  final Offset offset;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final bool enable;

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
  void dispose() {
    controller.close();
    isHoverMenuShowing = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.enable
        ? buildHoverMouseRegion(
            buildPopover(),
            cursor: SystemMouseCursors.click,
          )
        : widget.child;
  }

  Widget buildPopover() {
    return AppFlowyPopover(
      controller: controller,
      direction: widget.direction,
      offset: widget.offset,
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
      onEnter: onEnter,
      onExit: onExit,
      child: child,
    );
  }

  void onEnter(PointerEnterEvent e) {
    widget.onEnter?.call(e);
    isHovering = true;
    Future.delayed(widget.delayToShow, () {
      if (isHovering && !isHoverMenuShowing) {
        showHoverMenu();
      }
    });
  }

  void onExit(PointerExitEvent e) {
    widget.onExit?.call(e);
    isHovering = false;
    tryToDismissenu();
  }

  void showHoverMenu() {
    if (isHoverMenuShowing || !mounted) {
      return;
    }
    keepEditorFocusNotifier.increase();
    controller.show();
    isHoverMenuShowing = true;
  }

  void tryToDismissenu() {
    Future.delayed(widget.delayToHide, () {
      if (isHovering) return;
      keepEditorFocusNotifier.decrease();
      controller.close();
      isHoverMenuShowing = false;
    });
  }
}
