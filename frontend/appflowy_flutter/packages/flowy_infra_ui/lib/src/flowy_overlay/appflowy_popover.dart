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
  final Future<bool> Function()? canClose;
  final PopoverMutex? mutex;
  final Offset? offset;
  final bool asBarrier;
  final EdgeInsets margin;
  final EdgeInsets windowPadding;
  final Decoration? decoration;

  const AppFlowyPopover({
    Key? key,
    required this.child,
    required this.popupBuilder,
    this.direction = PopoverDirection.rightWithTopAligned,
    this.onClose,
    this.canClose,
    this.constraints = const BoxConstraints(maxWidth: 240, maxHeight: 600),
    this.mutex,
    this.triggerActions = PopoverTriggerFlags.click,
    this.offset,
    this.controller,
    this.asBarrier = false,
    this.margin = const EdgeInsets.all(6),
    this.windowPadding = const EdgeInsets.all(8.0),
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Popover(
      controller: controller,
      onClose: onClose,
      canClose: canClose,
      direction: direction,
      mutex: mutex,
      asBarrier: asBarrier,
      triggerActions: triggerActions,
      windowPadding: windowPadding,
      offset: offset,
      popupBuilder: (context) {
        final child = popupBuilder(context);
        return _PopoverContainer(
          constraints: constraints,
          margin: margin,
          decoration: decoration,
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
  final Decoration? decoration;

  const _PopoverContainer({
    required this.child,
    required this.margin,
    required this.constraints,
    required this.decoration,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final decoration = this.decoration ??
        FlowyDecoration.decoration(
          Theme.of(context).cardColor,
          Theme.of(context).colorScheme.shadow,
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
