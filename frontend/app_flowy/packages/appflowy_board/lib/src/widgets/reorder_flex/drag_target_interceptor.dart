import 'dart:async';

import 'package:appflowy_board/src/widgets/board.dart';
import 'package:flutter/material.dart';
import '../../utils/log.dart';
import 'drag_state.dart';
import 'drag_target.dart';
import 'reorder_flex.dart';

/// [DragTargetInterceptor] is used to intercept the [DragTarget]'s
/// [onWillAccept], [OnAccept], and [onLeave] event.
abstract class DragTargetInterceptor {
  String get reorderFlexId;

  /// Returns [yes] to receive the [DragTarget]'s event.
  bool canHandler(FlexDragTargetData dragTargetData);

  /// Handle the [DragTarget]'s [onWillAccept] event.
  bool onWillAccept({
    required BuildContext context,
    required ReorderFlexState reorderFlexState,
    required FlexDragTargetData dragTargetData,
    required String dragTargetId,
    required int dragTargetIndex,
  });

  /// Handle the [DragTarget]'s [onAccept] event.
  void onAccept(FlexDragTargetData dragTargetData) {}

  /// Handle the [DragTarget]'s [onLeave] event.
  void onLeave(FlexDragTargetData dragTargetData) {}

  ReorderFlexDraggableTargetBuilder? get draggableTargetBuilder => null;
}

abstract class OverlapDragTargetDelegate {
  void cancel();
  void moveTo(
    String reorderFlexId,
    FlexDragTargetData dragTargetData,
    int dragTargetIndex,
  );

  int getInsertedIndex(String dragTargetId);
}

/// [OverlappingDragTargetInterceptor] is used to receive the overlapping
/// [DragTarget] event. If a [DragTarget] child is [DragTarget], it will
/// receive the [DragTarget] event when being dragged.
///
/// Receive the [DragTarget] event if the [acceptedReorderFlexId] contains
/// the passed in dragTarget' reorderFlexId.
class OverlappingDragTargetInterceptor extends DragTargetInterceptor {
  @override
  final String reorderFlexId;
  final List<String> acceptedReorderFlexId;
  final OverlapDragTargetDelegate delegate;
  final BoardColumnsState columnsState;
  Timer? _delayOperation;

  OverlappingDragTargetInterceptor({
    required this.delegate,
    required this.reorderFlexId,
    required this.acceptedReorderFlexId,
    required this.columnsState,
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
      delegate.cancel();
    } else {
      // Ignore the event if the dragTarget overlaps with the other column's dragTargets.
      final columnKeys = columnsState.columnDragDragTargets[dragTargetId];
      if (columnKeys != null) {
        final keys = columnKeys.values.toList();
        if (dragTargetData.isOverlapWithWidgets(keys)) {
          _delayOperation?.cancel();
          return true;
        }
      }

      /// The priority of the column interactions is high than the cross column.
      /// Workaround: delay 100 milliseconds to lower the cross column event priority.
      ///
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 100), () {
        final index = delegate.getInsertedIndex(dragTargetId);
        if (index != -1) {
          Log.trace(
              '[$OverlappingDragTargetInterceptor] move to $dragTargetId at $index');
          delegate.moveTo(dragTargetId, dragTargetData, index);

          columnsState
              .getReorderFlexState(columnId: dragTargetId)
              ?.resetDragTargetIndex(index);
        }
      });
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

class CrossReorderFlexDragTargetInterceptor extends DragTargetInterceptor {
  @override
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
      Log.trace(
          "[$CrossReorderFlexDragTargetInterceptor] $reorderFlexId accept ${dragTargetData.reorderFlexId} ${reorderFlexId != dragTargetData.reorderFlexId}");
      return reorderFlexId != dragTargetData.reorderFlexId;
    } else {
      Log.trace(
          "[$CrossReorderFlexDragTargetInterceptor] not accept ${dragTargetData.reorderFlexId}");
      return false;
    }
  }

  @override
  void onAccept(FlexDragTargetData dragTargetData) {
    Log.trace(
        '[$CrossReorderFlexDragTargetInterceptor] Column:[$reorderFlexId] on onAccept');
  }

  @override
  void onLeave(FlexDragTargetData dragTargetData) {
    Log.trace(
        '[$CrossReorderFlexDragTargetInterceptor] Column:[$reorderFlexId] on leave');
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

    Log.debug(
        '[$CrossReorderFlexDragTargetInterceptor] isNewDragTarget: $isNewDragTarget, dargTargetIndex: $dragTargetIndex, reorderFlexId: $reorderFlexId');

    if (isNewDragTarget == false) {
      delegate.updateDragTargetData(reorderFlexId, dragTargetIndex);
      reorderFlexState.handleOnWillAccept(context, dragTargetIndex);
    }

    return true;
  }
}
