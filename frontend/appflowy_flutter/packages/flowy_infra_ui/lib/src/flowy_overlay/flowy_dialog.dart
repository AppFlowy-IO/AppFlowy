import 'dart:math';

import 'package:flutter/material.dart';

const _overlayContainerPadding = EdgeInsets.symmetric(vertical: 12);
const overlayContainerMaxWidth = 760.0;
const overlayContainerMinWidth = 320.0;

class FlowyDialog extends StatelessWidget {
  const FlowyDialog({
    super.key,
    required this.child,
    this.title,
    this.shape,
    this.constraints,
    this.padding = _overlayContainerPadding,
    this.backgroundColor,
    this.width,
  });

  final Widget? title;
  final ShapeBorder? shape;
  final Widget child;
  final BoxConstraints? constraints;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.of(context).size;
    final size = windowSize * 0.6;
    return SimpleDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
        title: title,
        shape: shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        children: [
          Material(
            type: MaterialType.transparency,
            child: Container(
              height: size.height,
              width: width ??
                  max(
                    min(size.width, overlayContainerMaxWidth),
                    overlayContainerMinWidth,
                  ),
              constraints: constraints,
              child: child,
            ),
          )
        ]);
  }
}
