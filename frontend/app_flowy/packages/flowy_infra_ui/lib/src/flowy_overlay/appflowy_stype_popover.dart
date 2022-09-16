import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:appflowy_popover/popover.dart';
import 'package:flutter/material.dart';

class AppFlowyStylePopover extends StatelessWidget {
  final Widget child;
  final PopoverController? controller;
  final Widget Function(BuildContext context) popupBuilder;
  final PopoverDirection direction;
  final int triggerActions;
  final BoxConstraints? constraints;
  final void Function()? onClose;
  final PopoverMutex? mutex;
  final Offset? offset;

  const AppFlowyStylePopover({
    Key? key,
    required this.child,
    required this.popupBuilder,
    this.direction = PopoverDirection.rightWithTopAligned,
    this.onClose,
    this.constraints,
    this.mutex,
    this.triggerActions = 0,
    this.offset,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Popover(
      controller: controller,
      onClose: onClose,
      direction: direction,
      mutex: mutex,
      triggerActions: triggerActions,
      popupBuilder: (context) {
        final child = popupBuilder(context);
        debugPrint('$child popover');
        return OverlayContainer(
          constraints: constraints,
          child: popupBuilder(context),
        );
      },
      child: child,
    );
  }
}
