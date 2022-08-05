import 'package:flutter/material.dart';
import '../../../flowy_board.dart';
import '../../utils/log.dart';
import '../flex/drag_state.dart';
import '../flex/drag_target.dart';
import '../flex/drag_target_inteceptor.dart';
import 'phantom_state.dart';

abstract class BoardPhantomControllerDelegate {
  BoardColumnDataController? controller(String columnId);
}

mixin ColumnDataPhantomMixim {
  BoardColumnDataController? get;
}

class BoardPhantomController extends OverlapReorderFlexDragTargetDelegate
    with CrossReorderFlexDragTargetDelegate {
  final BoardPhantomControllerDelegate delegate;

  PhantomRecord? phantomRecord;

  final columnsState = ColumnPhantomStateController();

  BoardPhantomController({required this.delegate});

  bool get hasPhantom => phantomRecord != null;

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

  void columnEndDragging(String columnId) {
    columnsState.setColumnIsDragging(columnId, true);
    if (phantomRecord != null) {
      if (phantomRecord!.fromColumnId == columnId) {
        columnsState.notifyDidRemovePhantom(phantomRecord!.toColumnId);
      }
    }
    _swapColumnData();
  }

  void _swapColumnData() {
    if (phantomRecord == null) {
      return;
    }

    if (columnsState.isDragging(phantomRecord!.fromColumnId) == false) {
      return;
    }
    final item = delegate
        .controller(phantomRecord!.fromColumnId)
        ?.removeAt(phantomRecord!.fromColumnIndex);
    assert(item != null);
    assert(delegate
        .controller(phantomRecord!.toColumnId)
        ?.items[phantomRecord!.toColumnIndex] is PhantomColumnItem);
    delegate
        .controller(phantomRecord!.toColumnId)
        ?.replace(phantomRecord!.toColumnIndex, item!);

    Log.debug("[$BoardPhantomController] did move ${phantomRecord.toString()}");
    phantomRecord = null;
  }

  /// Update the column's phantom index if it exists.
  /// [toColumnId] the id of the column
  /// [dragTargetIndex] the index of the dragTarget
  void _updatePhantom(
    String toColumnId,
    int dragTargetIndex,
  ) {
    final columnDataController = delegate.controller(toColumnId);
    final index =
        columnDataController?.items.indexWhere((item) => item.isPhantom);
    if (index == null) return;

    assert(index != -1);
    if (index != -1) {
      if (index != dragTargetIndex) {
        // Log.debug('[$BoardPhantomController] update $toColumnId:$index to $toColumnId:$phantomIndex');
        final item = columnDataController!.removeAt(index, notify: false);
        columnDataController.insert(dragTargetIndex, item, notify: false);
      }
    }
  }

  /// Remove the phantom in the column if it contains phantom
  void _removePhantom(String columnId) {
    final index = delegate
        .controller(columnId)
        ?.items
        .indexWhere((item) => item.isPhantom);

    if (index == null) return;

    assert(index != -1);

    if (index != -1) {
      delegate.controller(columnId)?.removeAt(index);
      Log.debug(
          '[$BoardPhantomController] Column$columnId remove phantom, current count: ${delegate.controller(columnId)?.items.length}');
      columnsState.notifyDidRemovePhantom(columnId);
      columnsState.removeColumnListener(columnId);
    }
  }

  /// Insert the phantom into column
  ///
  /// * [toColumnId] id of the column
  /// * [phantomIndex] the phantom occupies index
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
    delegate
        .controller(toColumnId)
        ?.insert(phantomIndex, PhantomColumnItem(phantomContext));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        Log.debug(
            '[$BoardPhantomController] notify $toColumnId to insert phantom');
        columnsState.notifyDidInsertPhantom(toColumnId);
      });
    });
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
    // Log.debug('[$BoardPhantomController] move Column${dragTargetData.reorderFlexId}:${dragTargetData.draggingIndex} '
    //     'to Column$columnId:$index');

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
      _updatePhantom(phantomRecord!.toColumnId, dragTargetIndex);
    }
  }

  @override
  void dragTargetDidDisappear() {
    if (phantomRecord == null) {
      return;
    }

    _removePhantom(phantomRecord!.toColumnId);
    phantomRecord = null;
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
        '[$PhantomRecord] Update Column$fromColumnId remove position to $index');
    fromColumnIndex = index;
  }

  void updateInsertedIndex(int index) {
    if (toColumnIndex == index) {
      return;
    }

    Log.debug(
        '[$PhantomRecord] Column$toColumnId update position $toColumnIndex -> $index');
    toColumnIndex = index;
  }

  @override
  String toString() {
    return 'Column$fromColumnId:$fromColumnIndex to Column$toColumnId:$toColumnIndex';
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

  @override
  void fakeOnDragStarted(VoidCallback callback) {
    onInserted = callback;
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
  @override
  Widget? build<T extends DragTargetData>(
    BuildContext context,
    Widget child,
    DragTargetOnStarted onDragStarted,
    DragTargetOnEnded<T> onDragEnded,
    DragTargetWillAccpet<T> onWillAccept,
  ) {
    if (child is PassthroughPhantomWidget) {
      return FakeDragTarget<T>(
        eventTrigger: child.passthroughPhantomContext,
        eventData: child.passthroughPhantomContext,
        onDragStarted: onDragStarted,
        onDragEnded: onDragEnded,
        onWillAccept: onWillAccept,
        child: child,
      );
    } else {
      return null;
    }
  }
}
