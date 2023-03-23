import 'package:flutter/material.dart';
import 'dart:math';

const _overlayContainerPadding = EdgeInsets.symmetric(vertical: 12);
const overlayContainerMaxWidth = 760.0;
const overlayContainerMinWidth = 320.0;

class FlowyDialog extends StatelessWidget {
  final Widget? title;
  final ShapeBorder? shape;
  final Widget child;
  final BoxConstraints? constraints;
  final EdgeInsets padding;
  const FlowyDialog({
    required this.child,
    this.title,
    this.shape,
    this.constraints,
    this.padding = _overlayContainerPadding,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.of(context).size;
    final size = windowSize * 0.7;
    return SimpleDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: Theme.of(context).cardColor,
        title: title,
        shape: shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        children: [
          Material(
            type: MaterialType.transparency,
            child: Container(
              height: size.height,
              width: max(min(size.width, overlayContainerMaxWidth),
                  overlayContainerMinWidth),
              constraints: constraints,
              child: child,
            ),
          )
        ]);
  }
}
