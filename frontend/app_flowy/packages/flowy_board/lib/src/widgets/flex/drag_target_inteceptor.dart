import 'package:flutter/material.dart';

import '../../utils/log.dart';
import 'drag_state.dart';
import 'drag_target.dart';
import 'reorder_flex.dart';

abstract class ReorderFlexDragTargetInterceptor {
  bool canHandler(FlexDragTargetData dragTargetData);

  bool onWillAccept(
    BuildContext context,
    ReorderFlexState reorderFlexState,
    FlexDragTargetData dragTargetData,
    int itemIndex,
  );

  void onAccept(FlexDragTargetData dragTargetData);

  void onLeave(FlexDragTargetData dragTargetData);

  ReorderFlexDraggableTargetBuilder? get draggableTargetBuilder;
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
  final List<String> acceptReorderFlexIds;
  final CrossReorderFlexDragTargetDelegate delegate;
  @override
  final ReorderFlexDraggableTargetBuilder? draggableTargetBuilder;

  CrossReorderFlexDragTargetInterceptor({
    required this.reorderFlexId,
    required this.delegate,
    required this.acceptReorderFlexIds,
    this.draggableTargetBuilder,
  });

  @override
  bool canHandler(FlexDragTargetData dragTargetData) {
    if (acceptReorderFlexIds.isEmpty) {
      return true;
    }

    if (acceptReorderFlexIds.contains(dragTargetData.reorderFlexId)) {
      /// If the columnId equal to the dragTargetData's columnId,
      /// it means the dragTarget is dragging on the top of its own list.
      /// Otherwise, it means the dargTarget was moved to another list.
      return reorderFlexId != dragTargetData.reorderFlexId;
    } else {
      return false;
    }
  }

  @override
  bool onWillAccept(
    BuildContext context,
    ReorderFlexState reorderFlexState,
    FlexDragTargetData dragTargetData,
    int itemIndex,
  ) {
    final isNewDragTarget = delegate.acceptNewDragTargetData(
      reorderFlexId,
      dragTargetData,
      itemIndex,
    );

    if (isNewDragTarget == false) {
      delegate.updateDragTargetData(
        reorderFlexId,
        dragTargetData,
        itemIndex,
      );

      reorderFlexState.onWillAccept(
        context,
        dragTargetData.draggingIndex,
        itemIndex,
      );
    } else {
      Log.debug(
          '[$CrossReorderFlexDragTargetInterceptor] move Column${dragTargetData.reorderFlexId}:${dragTargetData.draggingIndex} '
          'to Column$reorderFlexId:$itemIndex');
    }

    return true;
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
}
