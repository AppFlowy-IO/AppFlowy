import 'dart:async';

import 'package:flutter/material.dart';

class FlowyCursorWidget extends StatefulWidget {
  const FlowyCursorWidget({
    Key? key,
    required this.layerLink,
    required this.rect,
    required this.color,
    this.blinkingInterval = 0.5,
  }) : super(key: key);

  final double blinkingInterval;
  final Color color;
  final Rect rect;
  final LayerLink layerLink;

  @override
  State<FlowyCursorWidget> createState() => _FlowyCursorWidgetState();
}

class _FlowyCursorWidgetState extends State<FlowyCursorWidget> {
  bool showCursor = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
        Duration(milliseconds: (widget.blinkingInterval * 1000).toInt()),
        (timer) {
      setState(() {
        showCursor = !showCursor;
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: widget.rect,
      child: CompositedTransformFollower(
        link: widget.layerLink,
        offset: Offset(widget.rect.center.dx, 0),
        showWhenUnlinked: true,
        child: Container(
          color: showCursor ? widget.color : Colors.transparent,
        ),
      ),
    );
  }
}
