import 'package:flutter/material.dart';

class FlowyOptionDecorateBox extends StatelessWidget {
  const FlowyOptionDecorateBox({
    super.key,
    this.showTopBorder = true,
    this.showBottomBorder = true,
    this.color,
    required this.child,
  });

  final bool showTopBorder;
  final bool showBottomBorder;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        border: Border(
          top: showTopBorder
              ? BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                )
              : BorderSide.none,
          bottom: showBottomBorder
              ? BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                )
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}
