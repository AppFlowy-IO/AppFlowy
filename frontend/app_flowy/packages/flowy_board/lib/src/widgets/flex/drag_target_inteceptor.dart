import 'package:flutter/material.dart';

import '../../utils/log.dart';
import 'drag_state.dart';
import 'drag_target.dart';
import 'reorder_flex.dart';

abstract class ReorderFlexDragTargetInterceptor {
  bool canHandler(FlexDragTargetData dragTargetData);

  bool onWillAccept({
    required BuildContext context,
    required ReorderFlexState reorderFlexState,
    required FlexDragTargetData dragTargetData,
    required String dragTargetId,
    required int dragTargetIndex,
  });

  void onAccept(FlexDragTargetData dragTargetData);

  void onLeave(FlexDragTargetData dragTargetData);

  ReorderFlexDraggableTargetBuilder? get draggableTargetBuilder;
}

abstract class OverlapReorderFlexDragTargetDelegate
    extends CrossReorderFlexDragTargetDelegate {}

class OverlapReorderFlexDragTargetInteceptor
    extends ReorderFlexDragTargetInterceptor {
  final String reorderFlexId;
  final List<String> acceptedReorderFlexId;
  final OverlapReorderFlexDragTargetDelegate delegate;

  OverlapReorderFlexDragTargetInteceptor({
    required this.delegate,
    required this.reorderFlexId,
    required this.acceptedReorderFlexId,
  });

  @override
  bool canHandler(FlexDragTargetData dragTargetData) {
    return acceptedReorderFlexId.contains(dragTargetData.reorderFlexId);
  }

  @override
  ReorderFlexDraggableTargetBuilder? get draggableTargetBuilder => null;

  @override
  void onAccept(FlexDragTargetData dragTargetData) {}

  @override
  void onLeave(FlexDragTargetData dragTargetData) {}

  @override
  bool onWillAccept(
      {required BuildContext context,
      required ReorderFlexState reorderFlexState,
      required FlexDragTargetData dragTargetData,
      required String dragTargetId,
      required int dragTargetIndex}) {
    Log.trace('dragTargetData: $dragTargetData');
    Log.trace('currentDragTargetId: $dragTargetId');
    //
    Log.debug('Switch to $dragTargetId');

    return true;
  }
}

abstract class CrossReorderFlexDragTargetDelegate {
  bool acceptNewDragTargetData(
    String columnId,
    FlexDragTargetData dragTargetData,
    int index,
  );
  void updateDragTargetData(
    String columnId,
    FlexDragTargetData dragTargetData,
    int index,
  );
}

class CrossReorderFlexDragTargetInterceptor
    extends ReorderFlexDragTargetInterceptor {
  final String reorderFlexId;
  final List<String> acceptedReorderFlexIds;
  final CrossReorderFlexDragTargetDelegate delegate;
  @override
  final ReorderFlexDraggableTargetBuilder? draggableTargetBuilder;

  CrossReorderFlexDragTargetInterceptor({
    required this.reorderFlexId,
    required this.delegate,
    required this.acceptedReorderFlexIds,
    this.draggableTargetBuilder,
  });

  @override
  bool canHandler(FlexDragTargetData dragTargetData) {
    if (acceptedReorderFlexIds.isEmpty) {
      return false;
    }

    if (acceptedReorderFlexIds.contains(dragTargetData.reorderFlexId)) {
      /// If the columnId equal to the dragTargetData's columnId,
      /// it means the dragTarget is dragging on the top of its own list.
      /// Otherwise, it means the dargTarget was moved to another list.
      return reorderFlexId != dragTargetData.reorderFlexId;
    } else {
      return false;
    }
  }

  @override
  void onAccept(FlexDragTargetData dragTargetData) {
    Log.trace(
        '[$CrossReorderFlexDragTargetInterceptor] Column$reorderFlexId on onAccept');
  }

  @override
  void onLeave(FlexDragTargetData dragTargetData) {
    Log.trace(
        '[$CrossReorderFlexDragTargetInterceptor] Column$reorderFlexId on leave');
  }

  @override
  bool onWillAccept(
      {required BuildContext context,
      required ReorderFlexState reorderFlexState,
      required FlexDragTargetData dragTargetData,
      required String dragTargetId,
      required int dragTargetIndex}) {
    final isNewDragTarget = delegate.acceptNewDragTargetData(
      reorderFlexId,
      dragTargetData,
      dragTargetIndex,
    );

    if (isNewDragTarget == false) {
      delegate.updateDragTargetData(
        reorderFlexId,
        dragTargetData,
        dragTargetIndex,
      );

      reorderFlexState.onWillAccept(
        context,
        dragTargetData.draggingIndex,
        dragTargetIndex,
      );
    } else {
      Log.debug(
          '[$CrossReorderFlexDragTargetInterceptor] move Column${dragTargetData.reorderFlexId}:${dragTargetData.draggingIndex} '
          'to Column$reorderFlexId:$dragTargetIndex');
    }

    return true;
  }
}
