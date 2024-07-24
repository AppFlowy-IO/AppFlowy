import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

class AppFlowyPopover extends StatelessWidget {
  final Widget child;
  final PopoverController? controller;
  final Widget Function(BuildContext context) popupBuilder;
  final PopoverDirection direction;
  final int triggerActions;
  final BoxConstraints constraints;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final Future<bool> Function()? canClose;
  final PopoverMutex? mutex;
  final Offset? offset;
  final bool asBarrier;
  final EdgeInsets margin;
  final EdgeInsets windowPadding;
  final Color? decorationColor;
  final BorderRadius? borderRadius;

  /// The widget that will be used to trigger the popover.
  ///
  /// Why do we need this?
  /// Because if the parent widget of the popover is GestureDetector,
  ///  the conflict won't be resolve by using Listener, we want these two gestures exclusive.
  final PopoverClickHandler clickHandler;

  /// If true the popover will not participate in focus traversal.
  ///
  final bool skipTraversal;

  const AppFlowyPopover({
    super.key,
    required this.child,
    required this.popupBuilder,
    this.direction = PopoverDirection.rightWithTopAligned,
    this.onOpen,
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
    this.clickHandler = PopoverClickHandler.listener,
    this.skipTraversal = false,
    this.decorationColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Popover(
      controller: controller,
      onOpen: onOpen,
      onClose: onClose,
      canClose: canClose,
      direction: direction,
      mutex: mutex,
      asBarrier: asBarrier,
      triggerActions: triggerActions,
      windowPadding: windowPadding,
      offset: offset,
      clickHandler: clickHandler,
      skipTraversal: skipTraversal,
      popupBuilder: (context) {
        return _PopoverContainer(
          constraints: constraints,
          margin: margin,
          decorationColor: decorationColor,
          borderRadius: borderRadius,
          child: popupBuilder(context),
        );
      },
      child: child,
    );
  }
}

class _PopoverContainer extends StatelessWidget {
  const _PopoverContainer({
    this.decorationColor,
    this.borderRadius,
    required this.child,
    required this.margin,
    required this.constraints,
  });

  final Widget child;
  final BoxConstraints constraints;
  final EdgeInsets margin;
  final Color? decorationColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: margin,
        decoration: context.getPopoverDecoration(
          color: decorationColor,
          borderRadius: borderRadius,
        ),
        constraints: constraints,
        child: child,
      ),
    );
  }
}

extension on BuildContext {
  /// The decoration of the popover.
  ///
  /// Don't customize the entire decoration of the popover,
  ///   use the built-in popoverDecoration instead and ask the designer before changing it.
  ShapeDecoration getPopoverDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    final borderColor = AFThemeExtension.of(this).borderColor;
    final shadows = [
      const BoxShadow(
        color: Color(0x0A1F2329),
        blurRadius: 24,
        offset: Offset(0, 8),
        spreadRadius: 8,
      ),
      const BoxShadow(
        color: Color(0x0A1F2329),
        blurRadius: 12,
        offset: Offset(0, 6),
        spreadRadius: 0,
      ),
      const BoxShadow(
        color: Color(0x0F1F2329),
        blurRadius: 8,
        offset: Offset(0, 4),
        spreadRadius: -8,
      )
    ];
    return ShapeDecoration(
      color: color ?? Theme.of(this).cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: 1,
          strokeAlign: BorderSide.strokeAlignOutside,
          color: borderColor,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(10),
      ),
      shadows: shadows,
    );
  }
}
