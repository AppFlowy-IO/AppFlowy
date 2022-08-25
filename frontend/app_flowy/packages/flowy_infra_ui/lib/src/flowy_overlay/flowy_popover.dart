import 'package:flutter/material.dart';

const _overlayContainerPadding = EdgeInsets.all(12);

class FlowyPopover extends StatelessWidget {
  final Widget child;
  final ShapeBorder? shape;

  FlowyPopover({Key? key, required this.child, this.shape}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      shape: shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      children: [Container(padding: _overlayContainerPadding, child: child)],
    );
  }

  static show(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
  }) {
    showDialog(
        barrierColor: Colors.transparent, context: context, builder: builder);
  }
}
