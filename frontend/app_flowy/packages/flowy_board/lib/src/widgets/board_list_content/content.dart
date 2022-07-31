import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../flowy_board.dart';
import '../../utils/log.dart';
import '../board_mixin.dart';
import '../drag_target.dart';
import 'state.dart';

typedef OnDragStarted = void Function(int index);
typedef OnDragEnded = void Function();
typedef OnReorder = void Function(int fromIndex, int toIndex);
typedef OnDeleted = void Function(int deletedIndex);
typedef OnInserted = void Function(int insertedIndex);
typedef OnReveivePassedInPhantom = void Function(DraggingContext draggingContext, int phantomIndex);

class BoardListContentWidget extends StatefulWidget with DraggingContextBoardList<BoardListItem> {
  final Widget? header;
  final Widget? footer;
  final BoardListData listData;
  final List<Widget> children;
  final BoardListItemWidgetBuilder builder;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final OnReveivePassedInPhantom onPassedInPhantom;
  final EdgeInsets? padding;
  final Axis direction = Axis.vertical;
  final MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;

  const BoardListContentWidget({
    Key? key,
    this.header,
    this.footer,
    required this.listData,
    required this.children,
    required this.builder,
    this.scrollController,
    required this.config,
    this.onDragStarted,
    required this.onReorder,
    this.onDragEnded,
    required this.onPassedInPhantom,
    // ignore: unused_element
    this.padding,
  }) : super(key: key);

  @override
  State<BoardListContentWidget> createState() => BoardListContentWidgetState();

  @override
  String get listId => listData.id;

  @override
  BoardListItem itemAtIndex(int index) {
    return listData.items[index];
  }
}

class BoardListContentWidgetState extends State<BoardListContentWidget>
    with BoardMixin, TickerProviderStateMixin<BoardListContentWidget> {
  // Controls scrolls and measures scroll progress.
  late ScrollController _scrollController;
  ScrollPosition? _attachedScrollPosition;
  // Whether or not we are currently scrolling this view to show a widget.
  bool _scrolling = false;

  late DragAnimationController _dragAnimationController;
  late DraggingState _dragState;

  BoardListContentWidget get currentBoardList => widget;

  @override
  void initState() {
    _dragState = DraggingState();
    _dragAnimationController = DragAnimationController(
      reorderAnimationDuration: widget.config.reorderAnimationDuration,
      scrollAnimationDuration: widget.config.scrollAnimationDuration,
      entranceAnimateStatusChanged: _onEntranceAnimationStatusChanged,
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

    _scrollController = widget.scrollController ?? PrimaryScrollController.of(context) ?? ScrollController();

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
    if (widget.header != null) {
      children.add(widget.header!);
    }

    for (int i = 0; i < widget.children.length; i += 1) {
      Widget child = widget.children[i];
      final wrapChild = _wrap(child, i);
      children.add(wrapChild);
    }

    if (widget.footer != null) {
      children.add(widget.footer!);
    }

    return _wrapScrollView(
      child: _wrapContainer(children),
    );
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

  void _onEntranceAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _requestAnimationToNextIndex();
      });
    }
  }

  void _requestAnimationToNextIndex({bool isAcceptingNewTarget = false}) {
    /// Update the dragState and animate to the next index if the current
    /// dragging animation is completed. Otherwise, it will get called again
    /// when the animation finishs.

    if (_dragAnimationController.isEntranceAnimationCompleted) {
      _dragState.removePhantom();

      if (!isAcceptingNewTarget && _dragState.didDragTargetMoveToNext()) {
        return;
      }

      _dragState.moveDragTargetToNext();
      _dragAnimationController.animateToNext();
    }
  }

  /// [child]: the child will be wrapped with dartTarget
  /// [childIndex]: the index of the child in a list
  Widget _wrap(Widget child, int childIndex) {
    return Builder(builder: (context) {
      final dragTarget = _buildDragTarget(context, child, childIndex);
      int shiftedIndex = childIndex;

      if (_dragState.isOverlapWithPhantom()) {
        shiftedIndex = _dragState.calculateShiftedIndex(childIndex);
        Log.trace('childIndex: $childIndex shiftedIndex: $shiftedIndex');
      }

      final currentIndex = _dragState.currentIndex;
      final dragPhantomIndex = _dragState.phantomIndex;

      if (shiftedIndex == currentIndex || childIndex == dragPhantomIndex) {
        Widget dragSpace;
        if (_dragState.draggingWidget != null) {
          if (_dragState.draggingWidget is PhantomWidget) {
            dragSpace = _dragState.draggingWidget!;
          } else {
            dragSpace = PhantomWidget(
              opacity: widget.config.draggingWidgetOpacity,
              child: _dragState.draggingWidget,
            );
          }
        } else {
          dragSpace = SizedBox.fromSize(size: _dragState.dropAreaSize);
        }

        /// Return the dragTarget it is not start dragging. The size of the
        /// dragTarget is the same as the the passed in child.
        ///
        if (_dragState.isNotDragging()) {
          return _buildDraggingContainer(children: [dragTarget]);
        }

        /// Determine the size of the drop area to show under the dragging widget.
        final feedbackSize = _dragState.feedbackSize;
        Widget appearSpace = _makeAppearSpace(dragSpace, feedbackSize);
        Widget disappearSpace = _makeDisappearSpace(dragSpace, feedbackSize);

        /// When start dragging, the dragTarget, [BoardDragTarget], will
        /// return a [IgnorePointerWidget] which size is zero.
        if (_dragState.isPhantomAboveDragTarget()) {
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
                children: shiftedIndex <= childIndex ? [dragTarget, disappearSpace] : [disappearSpace, dragTarget]);
          }
        }

        ///
        if (_dragState.isPhantomBelowDragTarget()) {
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
                children: shiftedIndex >= childIndex ? [disappearSpace, dragTarget] : [dragTarget, disappearSpace]);
          }
        }

        assert(!_dragState.isOverlapWithPhantom());

        List<Widget> children = [];
        if (_dragState.isDragTargetMovingDown()) {
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

  BoardDragTarget _buildDragTarget(BuildContext builderContext, Widget child, int childIndex) {
    return BoardDragTarget<DraggingContext>(
      draggingData: DraggingContext<BoardListItem>(
        draggingIndex: childIndex,
        state: _dragState,
        boardList: widget,
      ),
      onDragStarted: (draggingWidget, draggingIndex, size) {
        _startDragging(draggingWidget, draggingIndex, size);
        widget.onDragStarted?.call(draggingIndex);
      },
      onDragEnded: (draggingContext) {
        if (currentBoardList != draggingContext.boardList) {
          setState(() {
            _dragAnimationController.reverseAnimation();
            _dragState.endDragging();
            widget.onDragEnded?.call();
          });
        } else {
          setState(() {
            _onReordered(
              _dragState.dragStartIndex,
              _dragState.currentIndex,
            );
            _dragState.endDragging();
            widget.onDragEnded?.call();
          });
        }
      },
      onWillAccept: (DraggingContext draggingContext) {
        Log.trace('[$BoardDragTarget] ${widget.listData.id} on will accept');
        assert(widget.listData.items.length > childIndex);

        /// If the currentBoardList equal to the draggingContext's boardList,
        /// it means the dragTarget is dragging on the top of its own list.
        /// Otherwise, it means the dargTarget was moved to another list.
        ///
        if (currentBoardList != draggingContext.boardList) {
          Log.debug('Try move List${draggingContext.listId}:${draggingContext.draggingIndex} '
              'to List${widget.listData.id}:$childIndex');
          widget.onPassedInPhantom(draggingContext, childIndex);

          if (_dragState.isDragging()) {
            final dragIndex = draggingContext.draggingIndex;
            _onWillAccept(builderContext, dragIndex, childIndex);
          }

          return true;
        } else {
          final dragIndex = draggingContext.draggingIndex;
          return _onWillAccept(builderContext, dragIndex, childIndex);
        }
      },
      onAccept: (draggingContext) {
        Log.debug('[$BoardDragTarget] ${widget.listData.id} on onAccept');

        // if (currentBoardList != draggingContext.boardList) {
        //   /// The dragTarget was moved to another list.
        //   draggingContext.boardList.onDeleted(draggingContext.draggingIndex);
        //   widget.onInserted(childIndex);
        // }
      },
      onLeave: (draggingContext) {
        // Log.debug('[$BoardDragTarget] ${widget.listData.id} on leave');
      },
      child: child,
    );
  }

  void _startDragging(Widget draggingWidget, int dragIndex, Size? feedbackSize) {
    Log.trace('Start dragging: $draggingWidget at $dragIndex with feedbackSize: $feedbackSize');

    setState(() {
      _dragState.startDragging(draggingWidget, dragIndex, feedbackSize);
      _dragAnimationController.startDargging();
    });
  }

  bool _onWillAccept(BuildContext context, int? dragIndex, int childIndex) {
    /// The [willAccept] will be true if the dargTarget is the widget that gets
    /// dragged and it is dragged on top of the other dragTargets.
    bool willAccept = _dragState.dragStartIndex == dragIndex && dragIndex != childIndex;
    Log.trace("List${widget.listData.id}: dragIndex: $dragIndex, childIndex: $childIndex");
    setState(() {
      if (willAccept) {
        int shiftedIndex = _dragState.calculateShiftedIndex(childIndex);
        _dragState.updateNextIndex(shiftedIndex);
      } else {
        _dragState.updateNextIndex(childIndex);
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
    if (widget.scrollController != null && PrimaryScrollController.of(context) == null) {
      return child;
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: widget.padding,
        controller: _scrollController,
        child: child,
      );
    }
  }

  Widget _wrapContainer(List<Widget> children) {
    switch (widget.direction) {
      case Axis.horizontal:
        return Row(children: children);
      case Axis.vertical:
      default:
        return Column(children: children);
    }
  }

  Widget _buildDraggingContainer({required List<Widget> children}) {
    switch (widget.direction) {
      case Axis.horizontal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: children,
        );
      case Axis.vertical:
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: children,
        );
    }
  }

// Scrolls to a target context if that context is not on the screen.
  void _scrollTo(BuildContext context) {
    if (_scrolling) return;
    final RenderObject contextObject = context.findRenderObject()!;
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(contextObject)!;
    // If and only if the current scroll offset falls in-between the offsets
    // necessary to reveal the selected context at the top or bottom of the
    // screen, then it is already on-screen.
    final double margin =
        widget.direction == Axis.horizontal ? _dragState.dropAreaSize.width : _dragState.dropAreaSize.height;
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
      final bool onScreen = scrollOffset <= topOffset && scrollOffset >= bottomOffset;

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
          setState(() {
            _scrolling = false;
          });
        });
      }
    }
  }
}
