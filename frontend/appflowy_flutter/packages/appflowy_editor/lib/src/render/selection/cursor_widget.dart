import 'dart:async';

import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:flutter/material.dart';

class CursorWidget extends StatefulWidget {
  const CursorWidget({
    Key? key,
    required this.layerLink,
    required this.rect,
    required this.color,
    this.blinkingInterval = 0.5,
    this.shouldBlink = true,
    this.cursorStyle = CursorStyle.verticalLine,
  }) : super(key: key);

  final double blinkingInterval; // milliseconds
  final bool shouldBlink;
  final CursorStyle cursorStyle;
  final Color color;
  final Rect rect;
  final LayerLink layerLink;

  @override
  State<CursorWidget> createState() => CursorWidgetState();
}

class CursorWidgetState extends State<CursorWidget> {
  bool showCursor = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();

    timer = _initTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Timer _initTimer() {
    return Timer.periodic(
        Duration(milliseconds: (widget.blinkingInterval * 1000).toInt()),
        (timer) {
      setState(() {
        showCursor = !showCursor;
      });
    });
  }

  /// force the cursor widget to show for a while
  show() {
    setState(() {
      showCursor = true;
    });
    timer.cancel();
    timer = _initTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: widget.rect,
      child: CompositedTransformFollower(
        link: widget.layerLink,
        offset: widget.rect.topCenter,
        showWhenUnlinked: true,
        // Ignore the gestures in cursor
        //  to solve the problem that cursor area cannot be selected.
        child: IgnorePointer(
          child: _buildCursor(context),
        ),
      ),
    );
  }

  Widget _buildCursor(BuildContext context) {
    var color = widget.color;
    if (widget.shouldBlink && !showCursor) {
      color = Colors.transparent;
    }
    switch (widget.cursorStyle) {
      case CursorStyle.verticalLine:
        return Container(
          color: color,
        );
      case CursorStyle.borderLine:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
          ),
        );
    }
  }
}
