import 'package:flutter/material.dart';

class DraggableItemTarget<T extends Object> extends StatefulWidget {
  const DraggableItemTarget({
    super.key,
    required this.child,
    this.onMove,
    this.onLeave,
    this.onAcceptWithDetails,
    this.onWillAcceptWithDetails,
  });

  final Widget child;
  final DragTargetMove<T>? onMove;
  final DragTargetLeave<T>? onLeave;
  final DragTargetAcceptWithDetails<T>? onAcceptWithDetails;
  final DragTargetWillAcceptWithDetails<T>? onWillAcceptWithDetails;

  @override
  State<DraggableItemTarget<T>> createState() => _DraggableItemTargetState<T>();
}

class _DraggableItemTargetState<T extends Object> extends State<DraggableItemTarget<T>> {
  @override
  Widget build(BuildContext context) {
    return DragTarget(
      onMove: widget.onMove,
      onLeave: widget.onLeave,
      builder: (_, __, ___) => widget.child,
      onAcceptWithDetails: widget.onAcceptWithDetails,
      onWillAcceptWithDetails: widget.onWillAcceptWithDetails,
    );
  }
}
