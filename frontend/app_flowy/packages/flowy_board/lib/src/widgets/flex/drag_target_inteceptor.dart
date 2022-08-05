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

  void onAccept(FlexDragTargetData dragTargetData) {}

  void onLeave(FlexDragTargetData dragTargetData) {}

  ReorderFlexDraggableTargetBuilder? get draggableTargetBuilder => null;
}

abstract class OverlapReorderFlexDragTargetDelegate {
  void dragTargetDidDisappear();
  bool acceptNewDragTargetData(
    String reorderFlexId,
    FlexDragTargetData dragTargetData,
    int dragTargetIndex,
  );
}

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
  bool onWillAccept(
      {required BuildContext context,
      required ReorderFlexState reorderFlexState,
      required FlexDragTargetData dragTargetData,
      required String dragTargetId,
      required int dragTargetIndex}) {
    if (dragTargetId == dragTargetData.reorderFlexId) {
      delegate.dragTargetDidDisappear();
    } else {
      delegate.acceptNewDragTargetData(
        dragTargetId,
        dragTargetData,
        dragTargetIndex,
      );
    }

    return true;
  }
}

abstract class CrossReorderFlexDragTargetDelegate {
  /// * [reorderFlexId] is the id that the [ReorderFlex] passed in.
  bool acceptNewDragTargetData(
    String reorderFlexId,
    FlexDragTargetData dragTargetData,
    int dragTargetIndex,
  );

  void updateDragTargetData(
    String reorderFlexId,
    int dragTargetIndex,
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
  bool onWillAccept({
    required BuildContext context,
    required ReorderFlexState reorderFlexState,
    required FlexDragTargetData dragTargetData,
    required String dragTargetId,
    required int dragTargetIndex,
  }) {
    final isNewDragTarget = delegate.acceptNewDragTargetData(
      reorderFlexId,
      dragTargetData,
      dragTargetIndex,
    );

    if (isNewDragTarget == false) {
      delegate.updateDragTargetData(reorderFlexId, dragTargetIndex);
      reorderFlexState.handleOnWillAccept(context, dragTargetIndex);
    }

    return true;
  }
}
