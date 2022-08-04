import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../utils/log.dart';
import 'reorder_mixin.dart';
import 'drag_target.dart';
import 'drag_state.dart';
import 'drag_target_inteceptor.dart';

typedef OnDragStarted = void Function(int index);
typedef OnDragEnded = void Function();
typedef OnReorder = void Function(int fromIndex, int toIndex);
typedef OnDeleted = void Function(int deletedIndex);
typedef OnInserted = void Function(int insertedIndex);
typedef OnReveivePassedInPhantom = void Function(
    FlexDragTargetData dragTargetData, int phantomIndex);

abstract class ReoderFlextDataSource {
  String get identifier;
  List<ReoderFlexItem> get items;
}

abstract class ReoderFlexItem {
  String get id;
}

class ReorderFlexConfig {
  final bool needsLongPressDraggable = true;
  final double draggingWidgetOpacity = 0.2;
  final Duration reorderAnimationDuration = const Duration(milliseconds: 250);
  final Duration scrollAnimationDuration = const Duration(milliseconds: 250);
  const ReorderFlexConfig();
}

class ReorderFlex extends StatefulWidget with DraggingReorderFlex {
  final ReorderFlexConfig config;

  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
  final ScrollController? scrollController;

  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;

  final ReoderFlextDataSource dataSource;

  final ReorderFlexDragTargetInterceptor? interceptor;

  const ReorderFlex({
    Key? key,
    this.scrollController,
    required this.dataSource,
    required this.children,
    required this.config,
    required this.onReorder,
    this.onDragStarted,
    this.onDragEnded,
    this.interceptor,
    this.padding,
    this.spacing,
    this.direction = Axis.vertical,
  }) : super(key: key);

  @override
  State<ReorderFlex> createState() => ReorderFlexState();

  @override
  String get reorderFlexId => dataSource.identifier;

  @override
  ReoderFlexItem itemAtIndex(int index) {
    return dataSource.items[index];
  }
}

class ReorderFlexState extends State<ReorderFlex>
    with ReorderFlexMinxi, TickerProviderStateMixin<ReorderFlex> {
  /// Controls scrolls and measures scroll progress.
  late ScrollController _scrollController;
  ScrollPosition? _attachedScrollPosition;

  /// Whether or not we are currently scrolling this view to show a widget.
  bool _scrolling = false;

  late DraggingState dragState;
  late DragAnimationController _dragAnimationController;

  @override
  void initState() {
    dragState = DraggingState(widget.reorderFlexId);

    _dragAnimationController = DragAnimationController(
      reorderAnimationDuration: widget.config.reorderAnimationDuration,
      scrollAnimationDuration: widget.config.scrollAnimationDuration,
      entranceAnimateStatusChanged: (status) {
        if (status == AnimationStatus.completed) {
          setState(() => _requestAnimationToNextIndex());
        }
      },
      vsync: this,
    );

    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_attachedScrollPosition != null) {
      _scrollController.detach(_attachedScrollPosition!);
      _attachedScrollPosition = null;
    }

    _scrollController = widget.scrollController ??
        PrimaryScrollController.of(context) ??
        ScrollController();

    if (_scrollController.hasClients) {
      _attachedScrollPosition = Scrollable.of(context)?.position;
    } else {
      _attachedScrollPosition = null;
    }

    if (_attachedScrollPosition != null) {
      _scrollController.attach(_attachedScrollPosition!);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    for (int i = 0; i < widget.children.length; i += 1) {
      Widget child = widget.children[i];

      if (widget.spacing != null) {
        children.add(SizedBox(width: widget.spacing!));
      }

      final wrapChild = _wrap(child, i);
      children.add(wrapChild);
    }

    final child = _wrapContainer(children);
    return _wrapScrollView(child: child);
  }

  @override
  void dispose() {
    if (_attachedScrollPosition != null) {
      _scrollController.detach(_attachedScrollPosition!);
      _attachedScrollPosition = null;
    }

    _dragAnimationController.dispose();
    super.dispose();
  }

  void _requestAnimationToNextIndex({bool isAcceptingNewTarget = false}) {
    /// Update the dragState and animate to the next index if the current
    /// dragging animation is completed. Otherwise, it will get called again
    /// when the animation finishs.

    if (_dragAnimationController.isEntranceAnimationCompleted) {
      dragState.removePhantom();

      if (!isAcceptingNewTarget && dragState.didDragTargetMoveToNext()) {
        return;
      }

      dragState.moveDragTargetToNext();
      _dragAnimationController.animateToNext();
    }
  }

  /// [child]: the child will be wrapped with dartTarget
  /// [childIndex]: the index of the child in a list
  Widget _wrap(Widget child, int childIndex) {
    return Builder(builder: (context) {
      final dragTarget = _buildDragTarget(context, child, childIndex);
      int shiftedIndex = childIndex;

      if (dragState.isOverlapWithPhantom()) {
        shiftedIndex = dragState.calculateShiftedIndex(childIndex);
      }

      Log.trace(
          'Rebuild: Column${dragState.id} ${dragState.toString()}, childIndex: $childIndex shiftedIndex: $shiftedIndex');
      final currentIndex = dragState.currentIndex;
      final dragPhantomIndex = dragState.phantomIndex;

      if (shiftedIndex == currentIndex || childIndex == dragPhantomIndex) {
        Widget dragSpace;
        if (dragState.draggingWidget != null) {
          if (dragState.draggingWidget is PhantomWidget) {
            dragSpace = dragState.draggingWidget!;
          } else {
            dragSpace = PhantomWidget(
              opacity: widget.config.draggingWidgetOpacity,
              child: dragState.draggingWidget,
            );
          }
        } else {
          dragSpace = SizedBox.fromSize(size: dragState.dropAreaSize);
        }

        /// Return the dragTarget it is not start dragging. The size of the
        /// dragTarget is the same as the the passed in child.
        ///
        if (dragState.isNotDragging()) {
          return _buildDraggingContainer(children: [dragTarget]);
        }

        /// Determine the size of the drop area to show under the dragging widget.
        final feedbackSize = dragState.feedbackSize;
        Widget appearSpace = _makeAppearSpace(dragSpace, feedbackSize);
        Widget disappearSpace = _makeDisappearSpace(dragSpace, feedbackSize);

        /// When start dragging, the dragTarget, [BoardDragTarget], will
        /// return a [IgnorePointerWidget] which size is zero.
        if (dragState.isPhantomAboveDragTarget()) {
          //the phantom is moving down, i.e. the tile below the phantom is moving up
          Log.trace('index:$childIndex item moving up / phantom moving down');
          if (shiftedIndex == currentIndex && childIndex == dragPhantomIndex) {
            return _buildDraggingContainer(children: [
              disappearSpace,
              dragTarget,
              appearSpace,
            ]);
          } else if (shiftedIndex == currentIndex) {
            return _buildDraggingContainer(children: [
              dragTarget,
              appearSpace,
            ]);
          } else if (childIndex == dragPhantomIndex) {
            return _buildDraggingContainer(
                children: shiftedIndex <= childIndex
                    ? [dragTarget, disappearSpace]
                    : [disappearSpace, dragTarget]);
          }
        }

        ///
        if (dragState.isPhantomBelowDragTarget()) {
          //the phantom is moving up, i.e. the tile above the phantom is moving down
          Log.trace('index:$childIndex item moving down / phantom moving up');
          if (shiftedIndex == currentIndex && childIndex == dragPhantomIndex) {
            return _buildDraggingContainer(children: [
              appearSpace,
              dragTarget,
              disappearSpace,
            ]);
          } else if (shiftedIndex == currentIndex) {
            return _buildDraggingContainer(children: [
              appearSpace,
              dragTarget,
            ]);
          } else if (childIndex == dragPhantomIndex) {
            return _buildDraggingContainer(
                children: shiftedIndex >= childIndex
                    ? [disappearSpace, dragTarget]
                    : [dragTarget, disappearSpace]);
          }
        }

        assert(!dragState.isOverlapWithPhantom());

        List<Widget> children = [];
        if (dragState.isDragTargetMovingDown()) {
          children.addAll([dragTarget, appearSpace]);
        } else {
          children.addAll([appearSpace, dragTarget]);
        }
        return _buildDraggingContainer(children: children);
      }

      /// We still wrap dragTarget with a container so that widget's depths are
      /// the same and it prevent's layout alignment issue
      return _buildDraggingContainer(children: [dragTarget]);
    });
  }

  ReorderDragTarget _buildDragTarget(
    BuildContext builderContext,
    Widget child,
    int dragTargetIndex,
  ) {
    final ReoderFlexItem item = widget.dataSource.items[dragTargetIndex];
    return ReorderDragTarget<FlexDragTargetData>(
      dragTargetData: FlexDragTargetData(
        draggingIndex: dragTargetIndex,
        state: dragState,
        draggingReorderFlex: widget,
        dragTargetId: item.id,
      ),
      onDragStarted: (draggingWidget, draggingIndex, size) {
        Log.debug("Column${widget.dataSource.identifier} start dragging");
        _startDragging(draggingWidget, draggingIndex, size);
        widget.onDragStarted?.call(draggingIndex);
      },
      onDragEnded: (dragTargetData) {
        Log.debug("Column${widget.dataSource.identifier} end dragging");

        setState(() {
          _onReordered(
            dragState.dragStartIndex,
            dragState.currentIndex,
          );
          dragState.endDragging();
          widget.onDragEnded?.call();
        });
      },
      onWillAccept: (FlexDragTargetData dragTargetData) {
        assert(widget.dataSource.items.length > dragTargetIndex);

        if (_interceptDragTarget(
          dragTargetData,
          (interceptor) => interceptor.onWillAccept(
            context: builderContext,
            reorderFlexState: this,
            dragTargetData: dragTargetData,
            dragTargetId: item.id,
            dragTargetIndex: dragTargetIndex,
          ),
        )) {
          return true;
        } else {
          Log.debug(
              '[$ReorderDragTarget] ${widget.dataSource.identifier} on will accept, count: ${widget.dataSource.items.length}');
          final dragIndex = dragTargetData.draggingIndex;
          return onWillAccept(builderContext, dragIndex, dragTargetIndex);
        }
      },
      onAccept: (dragTargetData) {
        _interceptDragTarget(
          dragTargetData,
          (interceptor) => interceptor.onAccept(dragTargetData),
        );
      },
      onLeave: (dragTargetData) {
        _interceptDragTarget(
          dragTargetData,
          (interceptor) => interceptor.onLeave(dragTargetData),
        );
      },
      draggableTargetBuilder: widget.interceptor?.draggableTargetBuilder,
      child: child,
    );
  }

  bool _interceptDragTarget(
    FlexDragTargetData dragTargetData,
    void Function(ReorderFlexDragTargetInterceptor) callback,
  ) {
    final interceptor = widget.interceptor;
    if (interceptor != null && interceptor.canHandler(dragTargetData)) {
      callback(interceptor);
      return true;
    } else {
      return false;
    }
  }

  Widget _makeAppearSpace(Widget child, Size? feedbackSize) {
    return makeAppearingWidget(
      child,
      _dragAnimationController.entranceController,
      feedbackSize,
      widget.direction,
    );
  }

  Widget _makeDisappearSpace(Widget child, Size? feedbackSize) {
    return makeDisappearingWidget(
      child,
      _dragAnimationController.phantomController,
      feedbackSize,
      widget.direction,
    );
  }

  void _startDragging(
    Widget draggingWidget,
    int dragIndex,
    Size? feedbackSize,
  ) {
    setState(() {
      dragState.startDragging(draggingWidget, dragIndex, feedbackSize);
      _dragAnimationController.startDargging();
    });
  }

  bool onWillAccept(BuildContext context, int? dragIndex, int childIndex) {
    /// The [willAccept] will be true if the dargTarget is the widget that gets
    /// dragged and it is dragged on top of the other dragTargets.
    bool willAccept =
        dragState.dragStartIndex == dragIndex && dragIndex != childIndex;
    setState(() {
      if (willAccept) {
        int shiftedIndex = dragState.calculateShiftedIndex(childIndex);
        dragState.updateNextIndex(shiftedIndex);
      } else {
        dragState.updateNextIndex(childIndex);
      }

      _requestAnimationToNextIndex(isAcceptingNewTarget: true);
    });

    _scrollTo(context);

    /// If the target is not the original starting point, then we will accept the drop.
    return willAccept;
  }

  void _onReordered(int fromIndex, int toIndex) {
    if (fromIndex != toIndex) {
      widget.onReorder.call(fromIndex, toIndex);
    }

    _dragAnimationController.reverseAnimation();
  }

  Widget _wrapScrollView({required Widget child}) {
    if (widget.scrollController != null &&
        PrimaryScrollController.of(context) == null) {
      return child;
    } else {
      return SingleChildScrollView(
        scrollDirection: widget.direction,
        padding: widget.padding,
        controller: _scrollController,
        child: child,
      );
    }
  }

  Widget _wrapContainer(List<Widget> children) {
    switch (widget.direction) {
      case Axis.horizontal:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: children,
        );
      case Axis.vertical:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: children,
        );
    }
  }

  Widget _buildDraggingContainer({required List<Widget> children}) {
    switch (widget.direction) {
      case Axis.horizontal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: children,
        );
      case Axis.vertical:
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: children,
        );
    }
  }

// Scrolls to a target context if that context is not on the screen.
  void _scrollTo(BuildContext context) {
    if (_scrolling) return;
    final RenderObject contextObject = context.findRenderObject()!;
    final RenderAbstractViewport viewport =
        RenderAbstractViewport.of(contextObject)!;
    // If and only if the current scroll offset falls in-between the offsets
    // necessary to reveal the selected context at the top or bottom of the
    // screen, then it is already on-screen.
    final double margin = widget.direction == Axis.horizontal
        ? dragState.dropAreaSize.width
        : dragState.dropAreaSize.height;
    if (_scrollController.hasClients) {
      final double scrollOffset = _scrollController.offset;
      final double topOffset = max(
        _scrollController.position.minScrollExtent,
        viewport.getOffsetToReveal(contextObject, 0.0).offset - margin,
      );
      final double bottomOffset = min(
        _scrollController.position.maxScrollExtent,
        viewport.getOffsetToReveal(contextObject, 1.0).offset + margin,
      );
      final bool onScreen =
          scrollOffset <= topOffset && scrollOffset >= bottomOffset;

      // If the context is off screen, then we request a scroll to make it visible.
      if (!onScreen) {
        _scrolling = true;
        _scrollController.position
            .animateTo(
          scrollOffset < bottomOffset ? bottomOffset : topOffset,
          duration: _dragAnimationController.scrollAnimationDuration,
          curve: Curves.easeInOut,
        )
            .then((void value) {
          setState(() => _scrolling = false);
        });
      }
    }
  }
}
