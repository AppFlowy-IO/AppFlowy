import 'package:flutter/material.dart';

class DraggableItemTarget<T extends Object> extends StatefulWidget {
  const DraggableItemTarget({
    super.key,
    required this.child,
    this.onAccept,
    this.onWillAccept,
    this.onMove,
    this.onLeave,
  });

  final Widget child;
  final DragTargetAccept<T>? onAccept;
  final DragTargetWillAccept<T>? onWillAccept;
  final DragTargetMove<T>? onMove;
  final DragTargetLeave<T>? onLeave;

  @override
  State<DraggableItemTarget<T>> createState() => _DraggableItemTargetState<T>();
}

class _DraggableItemTargetState<T extends Object>
    extends State<DraggableItemTarget<T>> {
  @override
  Widget build(BuildContext context) {
    return DragTarget(
      onAccept: widget.onAccept,
      onWillAccept: widget.onWillAccept,
      onMove: widget.onMove,
      onLeave: widget.onLeave,
      builder: (_, __, ___) => widget.child,
    );
  }
}
