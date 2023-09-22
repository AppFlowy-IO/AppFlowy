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
    this.onAccept,
    this.onWillAccept,
    this.onMove,
    this.onLeave,
    this.dragAnchorStrategy,
    this.enableAutoScroll = true,
    this.hitTestSize = const Size(100, 100),
  });

  final T data;

  final Widget child;
  final Widget? feedback;
  final Widget? childWhenDragging;

  final DragTargetAccept<T>? onAccept;
  final DragTargetWillAccept<T>? onWillAccept;
  final DragTargetMove<T>? onMove;
  final DragTargetLeave<T>? onLeave;
  final Offset Function(Draggable<Object>, BuildContext, Offset)?
      dragAnchorStrategy;

  /// Whether to enable auto scroll when dragging.
  ///
  /// If true, the draggable item must be wrapped inside a [Scrollable] widget.
  final bool enableAutoScroll;
  final Size hitTestSize;

  @override
  State<CombinedDraggableItem<T>> createState() =>
      _CombinedDraggableItemState<T>();
}

class _CombinedDraggableItemState<T extends Object>
    extends State<CombinedDraggableItem<T>> {
  ScrollableState? scrollable;
  EdgeDraggingAutoScroller? autoScroller;
  Rect? dragTarget;

  @override
  Widget build(BuildContext context) {
    return DraggableItemTarget(
      onAccept: widget.onAccept,
      onWillAccept: widget.onWillAccept,
      onMove: widget.onMove,
      onLeave: widget.onLeave,
      child: DraggableItem(
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
