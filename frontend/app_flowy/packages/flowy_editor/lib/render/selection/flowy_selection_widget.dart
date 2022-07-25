import 'package:flutter/material.dart';

class FlowySelectionWidget extends StatefulWidget {
  const FlowySelectionWidget({
    Key? key,
    required this.layerLink,
    required this.rect,
    required this.color,
  }) : super(key: key);

  final Color color;
  final Rect rect;
  final LayerLink layerLink;

  @override
  State<FlowySelectionWidget> createState() => _FlowySelectionWidgetState();
}

class _FlowySelectionWidgetState extends State<FlowySelectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: widget.rect,
      child: CompositedTransformFollower(
        link: widget.layerLink,
        offset: widget.rect.topLeft,
        showWhenUnlinked: true,
        child: Container(
          color: widget.color,
        ),
      ),
    );
  }
}
