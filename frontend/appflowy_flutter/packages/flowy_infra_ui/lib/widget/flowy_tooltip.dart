import 'package:flutter/material.dart';

const _tooltipWaitDuration = Duration(milliseconds: 300);

class FlowyTooltip extends StatelessWidget {
  const FlowyTooltip({
    super.key,
    this.message,
    this.richMessage,
    this.preferBelow,
    this.showDuration,
    this.margin,
    this.child,
  });

  final String? message;
  final InlineSpan? richMessage;
  final bool? preferBelow;
  final Duration? showDuration;
  final EdgeInsetsGeometry? margin;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      margin: margin,
      waitDuration: _tooltipWaitDuration,
      message: message,
      richMessage: richMessage,
      showDuration: showDuration,
      preferBelow: preferBelow,
      child: child,
    );
  }
}
