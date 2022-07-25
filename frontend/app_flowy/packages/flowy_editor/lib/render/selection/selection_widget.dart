import 'package:flutter/material.dart';

class SelectionWidget extends StatefulWidget {
  const SelectionWidget({
    Key? key,
    required this.layerLink,
    required this.rect,
    required this.color,
  }) : super(key: key);

  final Color color;
  final Rect rect;
  final LayerLink layerLink;

  @override
  State<SelectionWidget> createState() => _SelectionWidgetState();
}

class _SelectionWidgetState extends State<SelectionWidget> {
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
