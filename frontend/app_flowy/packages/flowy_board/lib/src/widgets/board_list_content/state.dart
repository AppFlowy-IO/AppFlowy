import 'package:flutter/material.dart';

import '../drag_target.dart';
import 'content.dart';

/// [DraggingContext] is used to store the custom dragging data. It can be used to
/// locate the index of the dragging widget in the [BoardList].
class DraggingContext<I> extends DraggingData {
  /// The index of the dragging target in the boardList.
  @override
  final int draggingIndex;

  final DraggingContextState state;

  Widget? get draggingWidget => state.draggingWidget;

  Size? get draggingFeedbackSize => state.feedbackSize;

  /// Indicate the dargging come from which [BoardListContentWidget].
  final DraggingContextBoardList<I> boardList;

  I get bindData => boardList.itemAtIndex(draggingIndex);

  String get listId => boardList.listId;

  DraggingContext({
    required this.draggingIndex,
    required this.state,
    required this.boardList,
  });
}

abstract class DraggingContextState {
  Widget? get draggingWidget;
  Size? get feedbackSize;
}

abstract class DraggingContextBoardList<I> {
  String get listId;
  I itemAtIndex(int index);
}

class DraggingState extends DraggingContextState {
  /// The member of widget.children currently being dragged.
  ///
  /// Null if no drag is underway.
  Widget? _draggingWidget;

  @override
  Widget? get draggingWidget => _draggingWidget;

  /// The last computed size of the feedback widget being dragged.
  Size? _draggingFeedbackSize = Size.zero;

  @override
  Size? get feedbackSize => _draggingFeedbackSize;

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

  bool isDragging() {
    return !isNotDragging();
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
