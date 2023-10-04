import 'package:flutter/material.dart';

const _tooltipWaitDuration = Duration(milliseconds: 300);

class FlowyTooltip {
  static Tooltip delayed({
    String? message,
    InlineSpan? richMessage,
    bool? preferBelow,
    Duration? showDuration,
    Widget? child,
  }) {
    return Tooltip(
      waitDuration: _tooltipWaitDuration,
      message: message,
      richMessage: richMessage,
      showDuration: showDuration,
      preferBelow: preferBelow,
      child: child,
    );
  }
}
