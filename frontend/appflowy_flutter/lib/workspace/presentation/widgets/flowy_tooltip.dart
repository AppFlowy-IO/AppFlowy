import 'package:flutter/material.dart';

const _tooltipWaitDuration = Duration(milliseconds: 300);

class FlowyTooltip {
  static Tooltip delayedTooltip({
    String? message,
    InlineSpan? richMessage,
    bool? preferBelow,
    Widget? child,
  }) {
    return Tooltip(
      waitDuration: _tooltipWaitDuration,
      message: message,
      richMessage: richMessage,
      preferBelow: preferBelow,
      child: child,
    );
  }
}
