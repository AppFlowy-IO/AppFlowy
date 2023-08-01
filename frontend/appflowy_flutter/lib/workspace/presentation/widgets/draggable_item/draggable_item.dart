import 'package:flutter/material.dart';

class DraggableItem<T extends Object> extends StatefulWidget {
  const DraggableItem({
    super.key,
    required this.child,
    required this.data,
    this.feedback,
    this.childWhenDragging,
    this.onAccept,
    this.onWillAccept,
    this.onMove,
    this.onLeave,
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

  /// Whether to enable auto scroll when dragging.
  ///
  /// If true, the draggable item must be wrapped inside a [Scrollable] widget.
  final bool enableAutoScroll;
  final Size hitTestSize;

  @override
  State<DraggableItem<T>> createState() => _DraggableItemState<T>();
}

class _DraggableItemState<T extends Object> extends State<DraggableItem<T>> {
  ScrollableState? scrollable;
  EdgeDraggingAutoScroller? autoScroller;
  Rect? dragTarget;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    initAutoScrollerIfNeeded(context);
  }

  @override
  Widget build(BuildContext context) {
    initAutoScrollerIfNeeded(context);

    return DragTarget(
      onAccept: widget.onAccept,
      onWillAccept: widget.onWillAccept,
      onMove: widget.onMove,
      onLeave: widget.onLeave,
      builder: (_, __, ___) => Draggable<T>(
        data: widget.data,
        feedback: widget.feedback ?? widget.child,
        childWhenDragging: widget.childWhenDragging ?? widget.child,
        child: widget.child,
        onDragUpdate: (details) {
          if (widget.enableAutoScroll) {
            dragTarget = details.globalPosition & widget.hitTestSize;
            autoScroller?.startAutoScrollIfNecessary(dragTarget!);
          }
        },
        onDragEnd: (details) {
          autoScroller?.stopAutoScroll();
          dragTarget = null;
        },
        onDraggableCanceled: (_, __) {
          autoScroller?.stopAutoScroll();
          dragTarget = null;
        },
      ),
    );
  }

  void initAutoScrollerIfNeeded(BuildContext context) {
    if (!widget.enableAutoScroll) {
      return;
    }

    scrollable = Scrollable.of(context);
    if (scrollable == null) {
      throw FlutterError(
        'DraggableItem must be wrapped inside a Scrollable widget '
        'when enableAutoScroll is true.',
      );
    }

    autoScroller?.stopAutoScroll();
    autoScroller = EdgeDraggingAutoScroller(
      scrollable!,
      onScrollViewScrolled: () {
        if (dragTarget != null) {
          autoScroller!.startAutoScrollIfNecessary(dragTarget!);
        }
      },
      velocityScalar: 20,
    );
  }
}
