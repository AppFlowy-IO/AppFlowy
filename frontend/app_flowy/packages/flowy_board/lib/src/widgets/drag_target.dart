import 'package:flutter/material.dart';

import '../utils/log.dart';

abstract class DraggingData {}

/// [BoardDragTarget] is a [DragTarget] that carries the index information of
/// the child.
///
/// The size of the [BoardDragTarget] will become zero when it start dragging.
///
class BoardDragTarget<T extends DraggingData> extends StatefulWidget {
  final Widget child;
  final T draggingData;

  final GlobalObjectKey _indexGlobalKey;

  /// Called when dragTarget is being dragging.
  final void Function(Widget, T, Size?) onDragStarted;

  final void Function() onDragEnded;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// [toAccept] represents the dragTarget index, which is the value passed in
  /// when creating the [BoardDragTarget].
  final bool Function(T toAccept) onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final void Function(T)? onAccept;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final void Function(T)? onLeave;

  BoardDragTarget({
    Key? key,
    required this.child,
    required this.draggingData,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onWillAccept,
    this.onAccept,
    this.onLeave,
  })  : _indexGlobalKey = GlobalObjectKey(child.key!),
        super(key: key);

  @override
  State<BoardDragTarget<T>> createState() => _BoardDragTargetState<T>();
}

class _BoardDragTargetState<T extends DraggingData> extends State<BoardDragTarget<T>> {
  /// Return the dragTarget's size
  Size? _draggingFeedbackSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    Widget dragTarget = DragTarget<T>(
      builder: _buildDraggableWidget,
      onWillAccept: (draggingData) {
        assert(draggingData != null);
        if (draggingData == null) return false;
        return widget.onWillAccept(draggingData);
      },
      onAccept: widget.onAccept,
      onLeave: (draggingData) {
        assert(draggingData != null);
        if (draggingData != null) {
          widget.onLeave?.call(draggingData);
        }
      },
    );

    dragTarget = KeyedSubtree(key: widget._indexGlobalKey, child: dragTarget);
    return dragTarget;
  }

  Widget _buildDraggableWidget(
    BuildContext context,
    List<T?> acceptedCandidates,
    List<dynamic> rejectedCandidates,
  ) {
    Widget feedbackBuilder = Builder(builder: (BuildContext context) {
      BoxConstraints contentSizeConstraints = BoxConstraints.loose(_draggingFeedbackSize!);
      return _buildDraggableFeedback(
        context,
        contentSizeConstraints,
        widget.child,
      );
    });

    return LongPressDraggable<DraggingData>(
      maxSimultaneousDrags: 1,
      data: widget.draggingData,
      ignoringFeedbackSemantics: false,
      feedback: feedbackBuilder,
      childWhenDragging: IgnorePointerWidget(child: widget.child),
      onDragStarted: () {
        _draggingFeedbackSize = widget._indexGlobalKey.currentContext?.size;
        widget.onDragStarted(
          widget.child,
          widget.draggingData,
          _draggingFeedbackSize,
        );
      },
      dragAnchorStrategy: childDragAnchorStrategy,
      // When the drag ends inside a DragTarget widget, the drag
      // succeeds, and we reorder the widget into position appropriately.
      onDragCompleted: () {
        widget.onDragEnded();
      },
      // When the drag does not end inside a DragTarget widget, the
      // drag fails, but we still reorder the widget to the last position it
      // had been dragged to.
      onDraggableCanceled: (Velocity velocity, Offset offset) => widget.onDragEnded(),
      child: widget.child,
    );
  }

  Widget _buildDraggableFeedback(BuildContext context, BoxConstraints constraints, Widget child) {
    return Transform(
      transform: Matrix4.rotationZ(0),
      alignment: FractionalOffset.topLeft,
      child: Material(
        elevation: 3.0,
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
        child: ConstrainedBox(constraints: constraints, child: child),
      ),
    );
  }
}

class DragAnimationController {
  // How long an animation to reorder an element in the list takes.
  final Duration reorderAnimationDuration;

  // How long an animation to scroll to an off-screen element in the
  // list takes.
  final Duration scrollAnimationDuration;

  // This controls the entrance of the dragging widget into a new place.
  late AnimationController entranceController;

  // This controls the 'phantom' of the dragging widget, which is left behind
  // where the widget used to be.
  late AnimationController phantomController;

  DragAnimationController({
    required this.reorderAnimationDuration,
    required this.scrollAnimationDuration,
    required TickerProvider vsync,
    required void Function(AnimationStatus) entranceAnimateStatusChanged,
  }) {
    entranceController = AnimationController(value: 1.0, vsync: vsync, duration: reorderAnimationDuration);
    phantomController = AnimationController(value: 0, vsync: vsync, duration: reorderAnimationDuration);
    entranceController.addStatusListener(entranceAnimateStatusChanged);
  }

  bool get isEntranceAnimationCompleted => entranceController.isCompleted;

  void startDargging() {
    entranceController.value = 1.0;
  }

  void animateToNext() {
    phantomController.reverse(from: 1.0);
    entranceController.forward(from: 0.0);
  }

  void reverseAnimation() {
    phantomController.reverse(from: 0.1);
    entranceController.reverse(from: 0.0);
  }

  void dispose() {
    entranceController.dispose();
    phantomController.dispose();
  }
}

class IgnorePointerWidget extends StatelessWidget {
  final Widget? child;
  const IgnorePointerWidget({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: 0,
        child: SizedBox(width: 0, height: 0, child: child),
      ),
    );
  }
}

class PhantomWidget extends StatelessWidget {
  final Widget? child;
  final double opacity;
  const PhantomWidget({
    this.child,
    this.opacity = 1.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: child,
    );
  }
}

class PassedInPhantomWidget extends PhantomWidget {
  final Size? feedbackSize;
  const PassedInPhantomWidget({
    Widget? child,
    required double opacity,
    this.feedbackSize,
    Key? key,
  }) : super(child: child, opacity: opacity, key: key);
}

class PhantomData {
  int _insertedIndex = -1;

  int get insertedIndex => _insertedIndex;

  bool get hasInsert => _insertedIndex != -1;

  set insertedIndex(int value) {
    if (_insertedIndex != value) {
      Log.trace('[$PhantomData] set insert index: $value');
      _insertedIndex = value;
    }
  }

  int _deletedIndex = -1;

  bool get hasDelete => _deletedIndex != -1;

  int get deletedIndex => _deletedIndex;

  set deleteIndex(int value) {
    if (_deletedIndex != value) {
      Log.trace('[$PhantomData] set delete index: $value');
      _deletedIndex = value;
    }
  }
}

class PhantomAnimateContorller {
  // How long an animation to reorder an element in the list takes.
  final Duration reorderAnimationDuration;
  late AnimationController appearController;
  late AnimationController disappearController;

  PhantomAnimateContorller({
    required TickerProvider vsync,
    required this.reorderAnimationDuration,
    required void Function(AnimationStatus) appearAnimateStatusChanged,
  }) {
    appearController = AnimationController(value: 1.0, vsync: vsync, duration: reorderAnimationDuration);
    disappearController = AnimationController(value: 0, vsync: vsync, duration: reorderAnimationDuration);
    appearController.addStatusListener(appearAnimateStatusChanged);
  }

  bool get isAppearAnimationCompleted => appearController.isCompleted;

  void animateToNext() {
    disappearController.reverse(from: 1.0);
    appearController.forward(from: 0.0);
  }

  void performReorderAnimation() {
    disappearController.reverse(from: 0.1);
    appearController.reverse(from: 0.0);
  }

  void dispose() {
    appearController.dispose();
    disappearController.dispose();
  }
}
