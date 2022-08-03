import 'package:flutter/material.dart';

import '../../utils/log.dart';
import 'drag_state.dart';
import 'drag_target.dart';
import 'reorder_flex.dart';

abstract class DragTargetExtensionDelegate {
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

class ReorderFlextDragTargetExtension {
  final String reorderFlexId;
  final List<String> acceptReorderFlexIds;
  final DragTargetExtensionDelegate delegate;
  final ReorderDraggableTargetBuilder? draggableTargetBuilder;

  ReorderFlextDragTargetExtension({
    required this.reorderFlexId,
    required this.delegate,
    required this.acceptReorderFlexIds,
    this.draggableTargetBuilder,
  });

  bool canHandler(FlexDragTargetData dragTargetData) {
    /// If the columnId equal to the dragTargetData's columnId,
    /// it means the dragTarget is dragging on the top of its own list.
    /// Otherwise, it means the dargTarget was moved to another list.
    ///
    if (!acceptReorderFlexIds.contains(dragTargetData.reorderFlexId)) {
      return false;
    }

    return reorderFlexId != dragTargetData.reorderFlexId;
  }

  bool onWillAccept(
    ReorderFlexState reorderFlexState,
    BuildContext context,
    FlexDragTargetData dragTargetData,
    bool isDragging,
    int dragIndex,
    int itemIndex,
  ) {
    final isNewDragTarget = delegate.acceptNewDragTargetData(
        reorderFlexId, dragTargetData, itemIndex);

    if (isNewDragTarget == false) {
      delegate.updateDragTargetData(reorderFlexId, dragTargetData, itemIndex);
      reorderFlexState.onWillAccept(context, dragIndex, itemIndex);
    } else {
      Log.debug(
          '[$ReorderFlextDragTargetExtension] move Column${dragTargetData.reorderFlexId}:${dragTargetData.draggingIndex} '
          'to Column$reorderFlexId:$itemIndex');
    }

    return true;
  }

  void onAccept(FlexDragTargetData dragTargetData) {
    Log.trace(
        '[$ReorderFlextDragTargetExtension] Column$reorderFlexId on onAccept');
  }

  void onLeave(FlexDragTargetData dragTargetData) {
    Log.trace(
        '[$ReorderFlextDragTargetExtension] Column$reorderFlexId on leave');
  }
}
