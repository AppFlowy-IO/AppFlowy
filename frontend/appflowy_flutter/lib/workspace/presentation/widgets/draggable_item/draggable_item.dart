import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class DraggableItem<T extends Object> extends StatefulWidget {
  const DraggableItem({
    super.key,
    required this.child,
    required this.data,
    this.feedback,
    this.childWhenDragging,
    this.dragAnchorStrategy,
    this.enableAutoScroll = true,
    this.hitTestSize = const Size(100, 100),
    this.onDragging,
  });

  final Widget child;
  final T data;
  final Widget? feedback;
  final Widget? childWhenDragging;
  final Offset Function(Draggable<Object>, BuildContext, Offset)? dragAnchorStrategy;

  /// Whether to enable auto scroll when dragging.
  ///
  /// If true, the draggable item must be wrapped inside a [Scrollable] widget.
  final bool enableAutoScroll;

  final Size hitTestSize;
  final void Function(bool isDragging)? onDragging;

  @override
  State<DraggableItem> createState() => _DraggableItemState<T>();
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

    return _Draggable<T>(
      data: widget.data,
      feedback: widget.feedback ?? widget.child,
      childWhenDragging: widget.childWhenDragging ?? widget.child,
      onDragUpdate: (details) {
        if (widget.enableAutoScroll) {
          dragTarget = details.globalPosition & widget.hitTestSize;
          autoScroller?.startAutoScrollIfNecessary(dragTarget!);
        }
        widget.onDragging?.call(true);
      },
      onDragEnd: (details) {
        autoScroller?.stopAutoScroll();
        dragTarget = null;
        widget.onDragging?.call(false);
      },
      onDraggableCanceled: (_, __) {
        autoScroller?.stopAutoScroll();
        dragTarget = null;
        widget.onDragging?.call(false);
      },
      dragAnchorStrategy: widget.dragAnchorStrategy,
      child: widget.child,
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

class _Draggable<T extends Object> extends StatelessWidget {
  const _Draggable({
    required this.child,
    required this.feedback,
    this.data,
    this.childWhenDragging,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.dragAnchorStrategy,
  });

  final Widget child;
  final Widget feedback;
  final Widget? childWhenDragging;

  /// The data that will be dropped by this draggable.
  final T? data;

  /// Called when the draggable starts being dragged.
  final VoidCallback? onDragStarted;

  final DragUpdateCallback? onDragUpdate;
  final DraggableCanceledCallback? onDraggableCanceled;
  final DragEndCallback? onDragEnd;
  final VoidCallback? onDragCompleted;
  final Offset Function(Draggable<Object>, BuildContext, Offset)? dragAnchorStrategy;

  @override
  Widget build(BuildContext context) {
    return PlatformExtension.isMobile
        ? LongPressDraggable<T>(
            data: data,
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
            onDraggableCanceled: onDraggableCanceled,
            child: child,
          )
        : Draggable<T>(
            data: data,
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
            onDraggableCanceled: onDraggableCanceled,
            dragAnchorStrategy: dragAnchorStrategy ?? childDragAnchorStrategy,
            child: child,
          );
  }
}
