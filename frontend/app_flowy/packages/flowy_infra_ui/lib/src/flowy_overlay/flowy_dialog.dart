import 'package:flutter/material.dart';
import 'dart:math';

const overlayContainerPadding = EdgeInsets.all(12);
const overlayContainerMaxWidth = 760.0;
const overlayContainerMinWidth = 320.0;

class FlowyDialog extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final BoxConstraints? constraints;
  final EdgeInsets padding;
  const FlowyDialog({
    required this.child,
    this.title,
    this.constraints,
    this.padding = overlayContainerPadding,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.of(context).size;
    final size = windowSize * 0.7;
    return SimpleDialog(title: title, children: [
      Material(
        type: MaterialType.transparency,
        child: Container(
          padding: padding,
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
