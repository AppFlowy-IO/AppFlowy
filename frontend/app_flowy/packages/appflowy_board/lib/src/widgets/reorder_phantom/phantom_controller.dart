import 'package:flutter/material.dart';
import '../../utils/log.dart';
import '../board_column/board_column_data.dart';
import '../reorder_flex/drag_state.dart';
import '../reorder_flex/drag_target.dart';
import '../reorder_flex/drag_target_inteceptor.dart';
import 'phantom_state.dart';

abstract class BoardPhantomControllerDelegate {
  BoardColumnDataController? controller(String columnId);

  bool removePhantom(String columnId);

  /// Insert the phantom into column
  ///
  /// * [toColumnId] id of the column
  /// * [phantomIndex] the phantom occupies index
  void insertPhantom(
    String columnId,
    int index,
    PhantomColumnItem item,
  );

  /// Update the column's phantom index if it exists.
  /// [toColumnId] the id of the column
  /// [dragTargetIndex] the index of the dragTarget
  void updatePhantom(String columnId, int newIndex);

  void swapColumnItem(
    String fromColumnId,
    int fromColumnIndex,
    String toColumnId,
    int toColumnIndex,
  );
}

class BoardPhantomController extends OverlapDragTargetDelegate
    with CrossReorderFlexDragTargetDelegate {
  PhantomRecord? phantomRecord;
  final BoardPhantomControllerDelegate delegate;
  final columnsState = ColumnPhantomStateController();
  BoardPhantomController({required this.delegate});

  bool isFromColumn(String columnId) {
    if (phantomRecord != null) {
      return phantomRecord!.fromColumnId == columnId;
    } else {
      return true;
    }
  }

  void transformIndex(int fromIndex, int toIndex) {
    if (phantomRecord == null) {
      return;
    }
    assert(phantomRecord!.fromColumnIndex == fromIndex);
    phantomRecord?.updateFromColumnIndex(toIndex);
  }

  void columnStartDragging(String columnId) {
    columnsState.setColumnIsDragging(columnId, false);
  }

  /// Remove the phanton in the column when the column is end dragging.
  void columnEndDragging(String columnId) {
    columnsState.setColumnIsDragging(columnId, true);
    if (phantomRecord == null) return;

    final fromColumnId = phantomRecord!.fromColumnId;
    final toColumnId = phantomRecord!.toColumnId;
    if (fromColumnId == columnId) {
      columnsState.notifyDidRemovePhantom(toColumnId);
    }

    if (columnsState.isDragging(fromColumnId) == false) {
      return;
    }

    delegate.swapColumnItem(
      fromColumnId,
      phantomRecord!.fromColumnIndex,
      toColumnId,
      phantomRecord!.toColumnIndex,
    );

    Log.debug("[$BoardPhantomController] did move ${phantomRecord.toString()}");
    phantomRecord = null;
  }

  /// Remove the phantom in the column if it contains phantom
  void _removePhantom(String columnId) {
    if (delegate.removePhantom(columnId)) {
      columnsState.notifyDidRemovePhantom(columnId);
      columnsState.removeColumnListener(columnId);
    }
  }

  void _insertPhantom(
    String toColumnId,
    FlexDragTargetData dragTargetData,
    int phantomIndex,
  ) {
    final phantomContext = PassthroughPhantomContext(
      index: phantomIndex,
      dragTargetData: dragTargetData,
    );
    columnsState.addColumnListener(toColumnId, phantomContext);

    delegate.insertPhantom(
      toColumnId,
      phantomIndex,
      PhantomColumnItem(phantomContext),
    );

    columnsState.notifyDidInsertPhantom(toColumnId);
  }

  /// Reset or initial the [PhantomRecord]
  ///
  ///
  /// * [columnId] the id of the column
  /// * [dragTargetData]
  /// * [dragTargetIndex]
  ///
  void _resetPhantomRecord(
    String columnId,
    FlexDragTargetData dragTargetData,
    int dragTargetIndex,
  ) {
    // Log.debug('[$BoardPhantomController] move Column:[${dragTargetData.reorderFlexId}]:${dragTargetData.draggingIndex} '
    //     'to Column:[$columnId]:$index');

    phantomRecord = PhantomRecord(
      toColumnId: columnId,
      toColumnIndex: dragTargetIndex,
      fromColumnId: dragTargetData.reorderFlexId,
      fromColumnIndex: dragTargetData.draggingIndex,
    );
    Log.debug('[$BoardPhantomController] will move: $phantomRecord');
  }

  @override
  bool acceptNewDragTargetData(
    String reorderFlexId,
    FlexDragTargetData dragTargetData,
    int dragTargetIndex,
  ) {
    if (phantomRecord == null) {
      _resetPhantomRecord(reorderFlexId, dragTargetData, dragTargetIndex);
      _insertPhantom(reorderFlexId, dragTargetData, dragTargetIndex);
      return false;
    }

    final isNewDragTarget = phantomRecord!.toColumnId != reorderFlexId;
    if (isNewDragTarget) {
      /// Remove the phantom when the dragTarget is moved from one column to another column.
      _removePhantom(phantomRecord!.toColumnId);
      _resetPhantomRecord(reorderFlexId, dragTargetData, dragTargetIndex);
      _insertPhantom(reorderFlexId, dragTargetData, dragTargetIndex);
    }

    return isNewDragTarget;
  }

  @override
  void updateDragTargetData(
    String reorderFlexId,
    int dragTargetIndex,
  ) {
    phantomRecord?.updateInsertedIndex(dragTargetIndex);

    assert(phantomRecord != null);
    if (phantomRecord!.toColumnId == reorderFlexId) {
      /// Update the existing phantom index
      delegate.updatePhantom(phantomRecord!.toColumnId, dragTargetIndex);
    }
  }

  @override
  void cancel() {
    if (phantomRecord == null) {
      return;
    }

    /// Remove the phantom when the dragTarge is go back to the original column.
    _removePhantom(phantomRecord!.toColumnId);
    phantomRecord = null;
  }

  @override
  void moveTo(
    String reorderFlexId,
    FlexDragTargetData dragTargetData,
    int dragTargetIndex,
  ) {
    acceptNewDragTargetData(
      reorderFlexId,
      dragTargetData,
      dragTargetIndex,
    );
  }

  @override
  bool canMoveTo(String dragTargetId) {
    return delegate.controller(dragTargetId)?.columnData.items.isEmpty ?? false;
  }
}

/// Use [PhantomRecord] to record where to remove the column item and where to
/// insert the column item.
///
/// [fromColumnId] the column that phantom comes from
/// [fromColumnIndex] the index of the phantom from the original column
/// [toColumnId] the column that the phantom moves into
/// [toColumnIndex] the index of the phantom moves into the column
///
class PhantomRecord {
  final String fromColumnId;
  int fromColumnIndex;

  final String toColumnId;
  int toColumnIndex;

  PhantomRecord({
    required this.toColumnId,
    required this.toColumnIndex,
    required this.fromColumnId,
    required this.fromColumnIndex,
  });

  void updateFromColumnIndex(int index) {
    if (fromColumnIndex == index) {
      return;
    }
    Log.debug(
        '[$PhantomRecord] Update Column:[$fromColumnId] remove position to $index');
    fromColumnIndex = index;
  }

  void updateInsertedIndex(int index) {
    if (toColumnIndex == index) {
      return;
    }

    Log.debug(
        '[$PhantomRecord] Column:[$toColumnId] update position $toColumnIndex -> $index');
    toColumnIndex = index;
  }

  @override
  String toString() {
    return 'Column:[$fromColumnId]:$fromColumnIndex to Column:[$toColumnId]:$toColumnIndex';
  }
}

class PhantomColumnItem extends ColumnItem {
  final PassthroughPhantomContext phantomContext;

  PhantomColumnItem(PassthroughPhantomContext insertedPhantom)
      : phantomContext = insertedPhantom;

  @override
  bool get isPhantom => true;

  @override
  String get id => phantomContext.itemData.id;

  Size? get feedbackSize => phantomContext.feedbackSize;

  Widget get draggingWidget => phantomContext.draggingWidget == null
      ? const SizedBox()
      : phantomContext.draggingWidget!;

  @override
  String toString() {
    return 'phantom:$id';
  }
}

class PassthroughPhantomContext extends FakeDragTargetEventTrigger
    with FakeDragTargetEventData, PassthroughPhantomListener {
  @override
  int index;

  @override
  final FlexDragTargetData dragTargetData;

  @override
  Size? get feedbackSize => dragTargetData.feedbackSize;

  Widget? get draggingWidget => dragTargetData.draggingWidget;

  ColumnItem get itemData => dragTargetData.reorderFlexItem as ColumnItem;

  @override
  VoidCallback? onInserted;

  @override
  VoidCallback? onDragEnded;

  PassthroughPhantomContext({
    required this.index,
    required this.dragTargetData,
  });

  @override
  void fakeOnDragEnded(VoidCallback callback) {
    onDragEnded = callback;
  }
}

class PassthroughPhantomWidget extends PhantomWidget {
  final PassthroughPhantomContext passthroughPhantomContext;

  PassthroughPhantomWidget({
    required double opacity,
    required this.passthroughPhantomContext,
    Key? key,
  }) : super(
          child: passthroughPhantomContext.draggingWidget,
          opacity: opacity,
          key: key,
        );
}

class PhantomDraggableBuilder extends ReorderFlexDraggableTargetBuilder {
  PhantomDraggableBuilder();
  @override
  Widget? build<T extends DragTargetData>(
    BuildContext context,
    Widget child,
    DragTargetOnStarted onDragStarted,
    DragTargetOnEnded<T> onDragEnded,
    DragTargetWillAccpet<T> onWillAccept,
    AnimationController insertAnimationController,
    AnimationController deleteAnimationController,
  ) {
    if (child is PassthroughPhantomWidget) {
      return FakeDragTarget<T>(
        eventTrigger: child.passthroughPhantomContext,
        eventData: child.passthroughPhantomContext,
        onDragStarted: onDragStarted,
        onDragEnded: onDragEnded,
        onWillAccept: onWillAccept,
        insertAnimationController: insertAnimationController,
        deleteAnimationController: deleteAnimationController,
        child: child,
      );
    } else {
      return null;
    }
  }
}
