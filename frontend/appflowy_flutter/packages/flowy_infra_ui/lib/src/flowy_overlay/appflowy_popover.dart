import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';

class AppFlowyPopover extends StatelessWidget {
  final Widget child;
  final PopoverController? controller;
  final Widget Function(BuildContext context) popupBuilder;
  final PopoverDirection direction;
  final int triggerActions;
  final BoxConstraints constraints;
  final void Function()? onClose;
  final PopoverMutex? mutex;
  final Offset? offset;
  final bool asBarrier;
  final EdgeInsets margin;
  final EdgeInsets windowPadding;

  const AppFlowyPopover({
    Key? key,
    required this.child,
    required this.popupBuilder,
    this.direction = PopoverDirection.rightWithTopAligned,
    this.onClose,
    this.constraints = const BoxConstraints(maxWidth: 240, maxHeight: 600),
    this.mutex,
    this.triggerActions = PopoverTriggerFlags.click,
    this.offset,
    this.controller,
    this.asBarrier = false,
    this.margin = const EdgeInsets.all(6),
    this.windowPadding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Popover(
      controller: controller,
      onClose: onClose,
      direction: direction,
      mutex: mutex,
      asBarrier: asBarrier,
      triggerActions: triggerActions,
      windowPadding: windowPadding,
      offset: offset,
      popupBuilder: (context) {
        final child = popupBuilder(context);
        debugPrint("Show popover: $child");
        return _PopoverContainer(
          constraints: constraints,
          margin: margin,
          child: child,
        );
      },
      child: child,
    );
  }
}

class _PopoverContainer extends StatelessWidget {
  final Widget child;
  final BoxConstraints constraints;
  final EdgeInsets margin;
  const _PopoverContainer({
    required this.child,
    required this.margin,
    required this.constraints,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final decoration = FlowyDecoration.decoration(
      Theme.of(context).colorScheme.surface,
      Theme.of(context).colorScheme.shadow.withOpacity(0.15),
    );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: margin,
        decoration: decoration,
        constraints: constraints,
        child: child,
      ),
    );
  }
}
