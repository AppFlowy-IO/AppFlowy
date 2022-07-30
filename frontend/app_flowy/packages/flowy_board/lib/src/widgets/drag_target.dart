import 'package:flutter/material.dart';

import '../../flowy_board.dart';
import '../utils/log.dart';

/// [BoardDragTarget] is a [DragTarget] that carries the index information of
/// the child.
///
/// The size of the [BoardDragTarget] will become zero when it start dragging.
///
class BoardDragTarget extends StatefulWidget {
  final Widget child;
  final DraggingData draggingData;

  final GlobalObjectKey _indexGlobalKey;

  /// Called when dragTarget is being dragging.
  final void Function(Widget, DraggingData, Size?) onDragStarted;

  final void Function() onDragEnded;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// [toAccept] represents the dragTarget index, which is the value passed in
  /// when creating the [BoardDragTarget].
  final bool Function(DraggingData toAccept) onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final void Function(DraggingData)? onAccept;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final void Function(DraggingData)? onLeave;

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
  State<BoardDragTarget> createState() => _BoardDragTargetState();
}

class _BoardDragTargetState extends State<BoardDragTarget> {
  /// Return the dragTarget's size
  Size? _draggingFeedbackSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    Widget dragTarget = DragTarget<DraggingContext>(
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
    List<DraggingContext?> acceptedCandidates,
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
      childWhenDragging: _buildNoSizedDraggingWidget(widget.child),
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

  Widget _buildNoSizedDraggingWidget(Widget child) {
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: 0,
        child: SizedBox(width: 0, height: 0, child: child),
      ),
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

class PhantomWidget extends StatelessWidget {
  final Widget? child;
  final double opacity;
  const PhantomWidget({
    this.child,
    required this.opacity,
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

class DraggingState {
  /// The member of widget.children currently being dragged.
  ///
  /// Null if no drag is underway.
  Widget? _draggingWidget;

  Widget? get draggingWidget => _draggingWidget;

  /// The last computed size of the feedback widget being dragged.
  Size? _draggingFeedbackSize = Size.zero;

  Size? get draggingFeedbackSize => _draggingFeedbackSize;

  /// The location that the dragging widget occupied before it started to drag.
  int dragStartIndex = -1;

  /// The index that the dragging widget most recently left.
  /// This is used to show an animation of the widget's position.
  int phantomIndex = -1;

  /// The index that the dragging widget currently occupies.
  int currentIndex = -1;

  /// The widget to move the dragging widget too after the current index.
  int nextIndex = 0;

  /// Whether or not we are currently scrolling this view to show a widget.
  bool scrolling = false;

  /// The additional margin to place around a computed drop area.
  static const double _dropAreaMargin = 0.0;

  Size get dropAreaSize {
    if (_draggingFeedbackSize == null) {
      return Size.zero;
    }
    return _draggingFeedbackSize! + const Offset(_dropAreaMargin, _dropAreaMargin);
  }

  void startDragging(Widget draggingWidget, int draggingWidgetIndex, Size? draggingWidgetSize) {
    ///
    _draggingWidget = draggingWidget;
    phantomIndex = draggingWidgetIndex;
    dragStartIndex = draggingWidgetIndex;
    currentIndex = draggingWidgetIndex;
    _draggingFeedbackSize = draggingWidgetSize;
  }

  void endDragging() {
    dragStartIndex = -1;
    phantomIndex = -1;
    currentIndex = -1;
    _draggingWidget = null;
  }

  /// When the phantomIndex and currentIndex are the same, it means the dragging
  /// widget did move to the destination location.
  void removePhantom() {
    phantomIndex = currentIndex;
  }

  /// The dragging widget overlaps with the phantom widget.
  bool isOverlapWithPhantom() {
    return currentIndex != phantomIndex;
  }

  bool isPhantomAboveDragTarget() {
    return currentIndex > phantomIndex;
  }

  bool isPhantomBelowDragTarget() {
    return currentIndex < phantomIndex;
  }

  bool didDragTargetMoveToNext() {
    return currentIndex == nextIndex;
  }

  /// Set the currentIndex to nextIndex
  void moveDragTargetToNext() {
    currentIndex = nextIndex;
  }

  void updateNextIndex(int index) {
    assert(index >= 0);

    nextIndex = index;
  }

  bool isNotDragging() {
    return dragStartIndex == -1;
  }

  /// When the _dragStartIndex less than the _currentIndex, it means the
  /// dragTarget is going down to the end of the list.
  bool isDragTargetMovingDown() {
    return dragStartIndex < currentIndex;
  }

  /// The index represents the widget original index of the list.
  int calculateShiftedIndex(int index) {
    int shiftedIndex = index;
    if (index == dragStartIndex) {
      shiftedIndex = phantomIndex;
    } else if (index > dragStartIndex && index <= phantomIndex) {
      /// phantom move up
      shiftedIndex--;
    } else if (index < dragStartIndex && index >= phantomIndex) {
      /// phantom move down
      shiftedIndex++;
    }
    return shiftedIndex;
  }
}

/// [DraggingContext] is used to store the custom dragging data. It can be used to
/// locate the index of the dragging widget in the [BoardList].
class DraggingContext extends DraggingData {
  /// The index of the dragging target in the boardList.
  final int dragIndex;

  final DraggingState state;

  Widget? get bindWidget => state.draggingWidget;

  /// Indicate the dargging come from which [BoardListContentWidget].
  final BoardListContentWidget boardList;

  BoardListItem get bindData => boardList.listData.items[dragIndex];

  String get listId => boardList.listData.id;

  DraggingContext({
    required this.dragIndex,
    required this.state,
    required this.boardList,
  });
}

abstract class DraggingData {}

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
