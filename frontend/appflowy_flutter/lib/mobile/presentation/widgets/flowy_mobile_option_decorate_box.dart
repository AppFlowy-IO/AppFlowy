import 'package:flutter/material.dart';

class FlowyOptionDecorateBox extends StatelessWidget {
  const FlowyOptionDecorateBox({
    super.key,
    this.showTopBorder = true,
    this.showBottomBorder = true,
    required this.child,
  });

  final bool showTopBorder;
  final bool showBottomBorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: showTopBorder
              ? BorderSide(
                  color: Theme.of(context).dividerColor,
                )
              : BorderSide.none,
          bottom: showBottomBorder
              ? BorderSide(
                  color: Theme.of(context).dividerColor,
                )
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}
