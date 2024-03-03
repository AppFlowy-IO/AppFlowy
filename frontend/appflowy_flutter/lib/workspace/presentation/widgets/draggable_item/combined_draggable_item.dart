import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_item.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_target.dart';
import 'package:flutter/material.dart';

class CombinedDraggableItem<T extends Object> extends StatefulWidget {
  const CombinedDraggableItem({
    super.key,
    required this.child,
    required this.data,
    this.feedback,
    this.childWhenDragging,
    this.onAcceptWithDetails,
    this.onWillAcceptWithDetails,
    this.onMove,
    this.onLeave,
    this.onDragging,
    this.dragAnchorStrategy,
    this.enableAutoScroll = true,
    this.hitTestSize = const Size(100, 100),
  });

  final Widget child;
  final T data;
  final Widget? feedback;
  final Widget? childWhenDragging;
  final DragTargetAcceptWithDetails<T>? onAcceptWithDetails;
  final DragTargetWillAcceptWithDetails<T>? onWillAcceptWithDetails;
  final DragTargetMove<T>? onMove;
  final DragTargetLeave<T>? onLeave;
  final void Function(bool)? onDragging;
  final Offset Function(Draggable<Object>, BuildContext, Offset)? dragAnchorStrategy;

  /// Whether to enable auto scroll when dragging.
  ///
  /// If true, the draggable item must be wrapped inside a [Scrollable] widget.
  final bool enableAutoScroll;

  final Size hitTestSize;

  @override
  State<CombinedDraggableItem<T>> createState() => _CombinedDraggableItemState<T>();
}

class _CombinedDraggableItemState<T extends Object> extends State<CombinedDraggableItem<T>> {
  @override
  Widget build(BuildContext context) {
    return DraggableItemTarget(
      onAcceptWithDetails: widget.onAcceptWithDetails,
      onWillAcceptWithDetails: widget.onWillAcceptWithDetails,
      onMove: widget.onMove,
      onLeave: widget.onLeave,
      child: DraggableItem(
        onDragging: widget.onDragging,
        data: widget.data,
        childWhenDragging: widget.childWhenDragging,
        dragAnchorStrategy: widget.dragAnchorStrategy,
        enableAutoScroll: widget.enableAutoScroll,
        feedback: widget.feedback,
        hitTestSize: widget.hitTestSize,
        key: widget.key,
        child: widget.child,
      ),
    );
  }
}
