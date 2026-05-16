import 'package:flutter/material.dart';

class ConstrainedFlexView extends StatelessWidget {
  final Widget child;
  final double minSize;
  final Axis axis;
  final EdgeInsets scrollPadding;

  const ConstrainedFlexView(this.minSize,
      {super.key,
      required this.child,
      this.axis = Axis.horizontal,
      this.scrollPadding = EdgeInsets.zero});

  bool get isHz => axis == Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final viewSize = isHz ? constraints.maxWidth : constraints.maxHeight;
        if (viewSize > minSize) return child;
        return Padding(
          padding: scrollPadding,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: isHz ? double.infinity : minSize,
                  maxWidth: isHz ? minSize : double.infinity),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
