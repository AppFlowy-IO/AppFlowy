import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../utils/log.dart';
import 'reorder_mixin.dart';
import 'drag_target.dart';
import 'drag_state.dart';
import 'drag_target_interceptor.dart';

typedef OnDragStarted = void Function(int index);
typedef OnDragEnded = void Function();
typedef OnReorder = void Function(int fromIndex, int toIndex);
typedef OnDeleted = void Function(int deletedIndex);
typedef OnInserted = void Function(int insertedIndex);
typedef OnReceivePassedInPhantom = void Function(
    FlexDragTargetData dragTargetData, int phantomIndex);

abstract class ReoderFlexDataSource {
  /// [identifier] represents the id the [ReorderFlex]. It must be unique.
  String get identifier;

  /// The number of [ReoderFlexItem]s will be displayed in the [ReorderFlex].
  UnmodifiableListView<ReoderFlexItem> get items;
}

/// Each item displayed in the [ReorderFlex] required to implement the [ReoderFlexItem].
abstract class ReoderFlexItem {
  /// [id] is used to identify the item. It must be unique.
  String get id;
}

abstract class ReorderDragTargetIndexKeyStorage {
  void addKey(String reorderFlexId, String key, GlobalObjectKey value);
  GlobalObjectKey? readKey(String reorderFlexId, String key);
}

class ReorderFlexConfig {
  /// The opacity of the dragging widget
  final double draggingWidgetOpacity = 0.3;

  // How long an animation to reorder an element
  final Duration reorderAnimationDuration = const Duration(milliseconds: 300);

  // How long an animation to scroll to an off-screen element
  final Duration scrollAnimationDuration = const Duration(milliseconds: 300);

  final bool useMoveAnimation;

  final bool useMovePlaceholder;

  const ReorderFlexConfig({
    this.useMoveAnimation = true,
  }) : useMovePlaceholder = !useMoveAnimation;
}

class ReorderFlex extends StatefulWidget {
  final ReorderFlexConfig config;
  final List<Widget> children;

  /// [direction] How to place the children, default is Axis.vertical
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;

  final ScrollController? scrollController;

  /// [onDragStarted] is called when start dragging
  final OnDragStarted? onDragStarted;

  /// [onReorder] is called when dragTarget did end dragging
  final OnReorder onReorder;

  /// [onDragEnded] is called when dragTarget did end dragging
  final OnDragEnded? onDragEnded;

  final ReoderFlexDataSource dataSource;

  final DragTargetInterceptor? interceptor;

  final DraggingStateStorage? dragStateStorage;

  final ReorderDragTargetIndexKeyStorage? dragTargetIndexKeyStorage;

  final bool reorderable;

  ReorderFlex({
    Key? key,
    this.scrollController,
    required this.dataSource,
    required this.children,
    required this.config,
    required this.onReorder,
    this.reorderable = true,
    this.dragStateStorage,
    this.dragTargetIndexKeyStorage,
    this.onDragStarted,
    this.onDragEnded,
    this.interceptor,
    this.direction = Axis.vertical,
  })  : assert(children.every((Widget w) => w.key != null),
            'All child must have a key.'),
        super(key: key);

  @override
  State<ReorderFlex> createState() => ReorderFlexState();

  String get reorderFlexId => dataSource.identifier;
}

class ReorderFlexState extends State<ReorderFlex>
    with ReorderFlexMinxi, TickerProviderStateMixin<ReorderFlex> {
  /// Controls scrolls and measures scroll progress.
  late ScrollController _scrollController;

  /// Records the position of the [Scrollable]
  ScrollPosition? _attachedScrollPosition;

  /// Whether or not we are currently scrolling this view to show a widget.
  bool _scrolling = false;

  /// [dragState] records the dragging state including dragStartIndex, and phantomIndex, etc.
  late DraggingState dragState;

  /// [_animation] controls the dragging animations
  late DragTargetAnimation _animation;

  late ReorderFlexNotifier _notifier;

  @override
  void initState() {
    _notifier = ReorderFlexNotifier();
    final flexId = widget.reorderFlexId;
    dragState = widget.dragStateStorage?.read(flexId) ??
        DraggingState(widget.reorderFlexId);
    Log.trace('[DragTarget] init dragState: $dragState');

    widget.dragStateStorage?.remove(flexId);

    _animation = DragTargetAnimation(
      reorderAnimationDuration: widget.config.reorderAnimationDuration,
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
      final ReoderFlexItem item = widget.dataSource.items[i];

      final indexKey = GlobalObjectKey(child.key!);
      // Save the index key for quick access
      widget.dragTargetIndexKeyStorage?.addKey(
        widget.reorderFlexId,
        item.id,
        indexKey,
      );

      children.add(_wrap(child, i, indexKey));

      // if (widget.config.useMovePlaceholder) {
      //   children.add(DragTargeMovePlaceholder(
      //     dragTargetIndex: i,
      //     delegate: _notifier,
      //   ));
      // }
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

    _animation.dispose();
    super.dispose();
  }

  void _requestAnimationToNextIndex({bool isAcceptingNewTarget = false}) {
    /// Update the dragState and animate to the next index if the current
    /// dragging animation is completed. Otherwise, it will get called again
    /// when the animation finish.

    if (_animation.entranceController.isCompleted) {
      dragState.removePhantom();

      if (!isAcceptingNewTarget && dragState.didDragTargetMoveToNext()) {
        return;
      }

      dragState.moveDragTargetToNext();
      _animation.animateToNext();
    }
  }

  /// [child]: the child will be wrapped with dartTarget
  /// [childIndex]: the index of the child in a list
  Widget _wrap(Widget child, int childIndex, GlobalObjectKey indexKey) {
    return Builder(builder: (context) {
      final ReorderDragTarget dragTarget =
          _buildDragTarget(context, child, childIndex, indexKey);
      int shiftedIndex = childIndex;

      if (dragState.isOverlapWithPhantom()) {
        shiftedIndex = dragState.calculateShiftedIndex(childIndex);
      }

      Log.trace(
          'Rebuild: Column:[${dragState.reorderFlexId}] ${dragState.toString()}, childIndex: $childIndex shiftedIndex: $shiftedIndex');
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

        /// Returns the dragTarget it is not start dragging. The size of the
        /// dragTarget is the same as the the passed in child.
        ///
        if (dragState.isNotDragging()) {
          return _buildDraggingContainer(children: [dragTarget]);
        }

        /// Determine the size of the drop area to show under the dragging widget.
        Size? feedbackSize = Size.zero;
        if (widget.config.useMoveAnimation) {
          feedbackSize = dragState.feedbackSize;
        }

        Widget appearSpace = _makeAppearSpace(dragSpace, feedbackSize);
        Widget disappearSpace = _makeDisappearSpace(dragSpace, feedbackSize);

        /// When start dragging, the dragTarget, [ReorderDragTarget], will
        /// return a [IgnorePointerWidget] which size is zero.
        if (dragState.isPhantomAboveDragTarget()) {
          _notifier.updateDragTargetIndex(currentIndex);
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
          _notifier.updateDragTargetIndex(currentIndex);
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
    GlobalObjectKey indexKey,
  ) {
    final reorderFlexItem = widget.dataSource.items[dragTargetIndex];
    return ReorderDragTarget<FlexDragTargetData>(
      indexGlobalKey: indexKey,
      dragTargetData: FlexDragTargetData(
        draggingIndex: dragTargetIndex,
        reorderFlexId: widget.reorderFlexId,
        reorderFlexItem: reorderFlexItem,
        state: dragState,
        dragTargetId: reorderFlexItem.id,
        dragTargetIndexKey: indexKey,
      ),
      onDragStarted: (draggingWidget, draggingIndex, size) {
        Log.debug(
            "[DragTarget] Column:[${widget.dataSource.identifier}] start dragging item at $draggingIndex");
        _startDragging(draggingWidget, draggingIndex, size);
        widget.onDragStarted?.call(draggingIndex);
        widget.dragStateStorage?.remove(widget.reorderFlexId);
      },
      onDragMoved: (dragTargetData, offset) {
        dragTargetData.dragTargetOffset = offset;
      },
      onDragEnded: (dragTargetData) {
        if (!mounted) return;

        Log.debug(
            "[DragTarget]: Column:[${widget.dataSource.identifier}] end dragging");
        _notifier.updateDragTargetIndex(-1);
        setState(() {
          if (dragTargetData.reorderFlexId == widget.reorderFlexId) {
            _onReordered(
              dragState.dragStartIndex,
              dragState.currentIndex,
            );
          }

          dragState.endDragging();
          widget.onDragEnded?.call();
        });
      },
      onWillAccept: (FlexDragTargetData dragTargetData) {
        // Do not receive any events if the Insert item is animating.
        if (_animation.insertController.isAnimating) {
          return false;
        }

        assert(widget.dataSource.items.length > dragTargetIndex);
        if (_interceptDragTarget(dragTargetData, (interceptor) {
          interceptor.onWillAccept(
            context: builderContext,
            reorderFlexState: this,
            dragTargetData: dragTargetData,
            dragTargetId: reorderFlexItem.id,
            dragTargetIndex: dragTargetIndex,
          );
        })) {
          return true;
        } else {
          return handleOnWillAccept(builderContext, dragTargetIndex);
        }
      },
      onAccept: (dragTargetData) {
        _interceptDragTarget(
          dragTargetData,
          (interceptor) => interceptor.onAccept(dragTargetData),
        );
      },
      onLeave: (dragTargetData) {
        _notifier.updateDragTargetIndex(-1);
        _interceptDragTarget(
          dragTargetData,
          (interceptor) => interceptor.onLeave(dragTargetData),
        );
      },
      insertAnimationController: _animation.insertController,
      deleteAnimationController: _animation.deleteController,
      draggableTargetBuilder: widget.interceptor?.draggableTargetBuilder,
      useMoveAnimation: widget.config.useMoveAnimation,
      draggable: widget.reorderable,
      child: child,
    );
  }

  bool _interceptDragTarget(
    FlexDragTargetData dragTargetData,
    void Function(DragTargetInterceptor) callback,
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
      _animation.entranceController,
      feedbackSize,
      widget.direction,
    );
  }

  Widget _makeDisappearSpace(Widget child, Size? feedbackSize) {
    return makeDisappearingWidget(
      child,
      _animation.phantomController,
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
      _animation.startDragging();
    });
  }

  void resetDragTargetIndex(int dragTargetIndex) {
    dragState.setStartDraggingIndex(dragTargetIndex);
    widget.dragStateStorage?.write(
      widget.reorderFlexId,
      dragState,
    );
  }

  bool handleOnWillAccept(BuildContext context, int dragTargetIndex) {
    final dragIndex = dragState.dragStartIndex;

    /// The [willAccept] will be true if the dargTarget is the widget that gets
    /// dragged and it is dragged on top of the other dragTargets.
    ///

    bool willAccept =
        dragState.dragStartIndex == dragIndex && dragIndex != dragTargetIndex;
    setState(() {
      if (willAccept) {
        int shiftedIndex = dragState.calculateShiftedIndex(dragTargetIndex);
        dragState.updateNextIndex(shiftedIndex);
      } else {
        dragState.updateNextIndex(dragTargetIndex);
      }
      _requestAnimationToNextIndex(isAcceptingNewTarget: true);
    });

    Log.trace(
        '[$ReorderDragTarget] ${widget.reorderFlexId} dragging state: $dragState}');

    _scrollTo(context);

    /// If the target is not the original starting point, then we will accept the drop.
    return willAccept;
  }

  void _onReordered(int fromIndex, int toIndex) {
    if (fromIndex != toIndex) {
      widget.onReorder.call(fromIndex, toIndex);
    }

    _animation.reverseAnimation();
  }

  Widget _wrapScrollView({required Widget child}) {
    if (widget.scrollController != null &&
        PrimaryScrollController.of(context) == null) {
      return child;
    } else {
      return SingleChildScrollView(
        scrollDirection: widget.direction,
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

  void scrollToBottom(VoidCallback? completed) {
    if (_scrolling) {
      completed?.call();
      return;
    }

    if (widget.dataSource.items.isNotEmpty) {
      final item = widget.dataSource.items.last;
      final indexKey = widget.dragTargetIndexKeyStorage?.readKey(
        widget.reorderFlexId,
        item.id,
      );
      if (indexKey == null) {
        completed?.call();
        return;
      }

      final indexContext = indexKey.currentContext;
      if (indexContext == null || _scrollController.hasClients == false) {
        completed?.call();
        return;
      }

      final renderObject = indexContext.findRenderObject();
      if (renderObject != null) {
        _scrolling = true;
        _scrollController.position
            .ensureVisible(
          renderObject,
          alignment: 0.5,
          duration: const Duration(milliseconds: 120),
        )
            .then((value) {
          setState(() {
            _scrolling = false;
            completed?.call();
          });
        });
      } else {
        completed?.call();
      }
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
        : dragState.dropAreaSize.height / 2.0;
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
          duration: widget.config.scrollAnimationDuration,
          curve: Curves.easeInOut,
        )
            .then((void value) {
          setState(() => _scrolling = false);
        });
      }
    }
  }
}
