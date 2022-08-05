import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

class BoardPhantomController extends OverlapReorderFlexDragTargetDelegate with CrossReorderFlexDragTargetDelegate {
  final BoardPhantomControllerDelegate delegate;

  PhantomRecord? phantomRecord;

  final columnsState = ColumnPassthroughStateController();

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
    final item = delegate.controller(phantomRecord!.fromColumnId)?.removeAt(phantomRecord!.fromColumnIndex);
    assert(item != null);
    assert(delegate.controller(phantomRecord!.toColumnId)?.items[phantomRecord!.toColumnIndex] is PhantomColumnItem);
    delegate.controller(phantomRecord!.toColumnId)?.replace(phantomRecord!.toColumnIndex, item!);

    Log.debug("[$BoardPhantomController] did move ${phantomRecord.toString()}");
    phantomRecord = null;
  }

  void _updatePhantom(
    String toColumnId,
    FlexDragTargetData dragTargetData,
    int phantomIndex,
  ) {
    final columnDataController = delegate.controller(toColumnId);
    final index = columnDataController?.items.indexWhere((item) => item.isPhantom);
    if (index == null) return;

    assert(index != -1);
    if (index != -1) {
      if (index != phantomIndex) {
        // Log.debug('[$BoardPhantomController] update $toColumnId:$index to $toColumnId:$phantomIndex');
        final item = columnDataController!.removeAt(index, notify: false);
        columnDataController.insert(phantomIndex, item, notify: false);
      }
    }
  }

  void _removePhantom(String columnId) {
    final index = delegate.controller(columnId)?.items.indexWhere((item) => item.isPhantom);

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

  void _insertPhantom(
    String toColumnId,
    FlexDragTargetData dragTargetData,
    int phantomIndex,
  ) {
    final items = delegate.controller(toColumnId)?.items;
    if (items == null) {
      return;
    }

    final phantomContext = PassthroughPhantomContext(
      index: phantomIndex,
      dragTargetData: dragTargetData,
    );
    columnsState.addColumnListener(toColumnId, phantomContext);
    Log.debug('$phantomContext');
    delegate.controller(toColumnId)?.insert(phantomIndex, PhantomColumnItem(phantomContext));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        columnsState.notifyDidInsertPhantom(toColumnId);
      });
    });
  }

  void _updatePhantomRecord(
    String columnId,
    FlexDragTargetData dragTargetData,
    int index,
  ) {
    // Log.debug('[$BoardPhantomController] move Column${dragTargetData.reorderFlexId}:${dragTargetData.draggingIndex} '
    //     'to Column$columnId:$index');

    phantomRecord = PhantomRecord(
      toColumnId: columnId,
      toColumnIndex: index,
      item: dragTargetData.reorderFlexItem as ColumnItem,
      fromColumnId: dragTargetData.reorderFlexId,
      fromColumnIndex: dragTargetData.draggingIndex,
    );
    Log.debug('[$BoardPhantomController] will move: $phantomRecord');
  }

  @override
  bool acceptNewDragTargetData(String reorderFlexId, FlexDragTargetData dragTargetData, int index) {
    if (phantomRecord == null) {
      _updatePhantomRecord(reorderFlexId, dragTargetData, index);
      _insertPhantom(reorderFlexId, dragTargetData, index);
      return false;
    }

    final isNewDragTarget = phantomRecord!.toColumnId != reorderFlexId;
    if (isNewDragTarget) {
      /// Remove the phantom in the previous column.
      _removePhantom(phantomRecord!.toColumnId);

      /// Update the record and insert the phantom to new column.
      _updatePhantomRecord(reorderFlexId, dragTargetData, index);
      _insertPhantom(reorderFlexId, dragTargetData, index);
    }

    return isNewDragTarget;
  }

  @override
  void updateDragTargetData(String reorderFlexId, FlexDragTargetData dragTargetData, int dragTargetIndex) {
    phantomRecord?.updateInsertedIndex(dragTargetIndex);

    assert(phantomRecord != null);
    if (phantomRecord!.toColumnId == reorderFlexId) {
      /// Update the existing phantom index
      _updatePhantom(phantomRecord!.toColumnId, dragTargetData, dragTargetIndex);
    }
  }
}

class PhantomRecord {
  final ColumnItem item;
  final String fromColumnId;
  int fromColumnIndex;

  final String toColumnId;
  int toColumnIndex;

  PhantomRecord({
    required this.item,
    required this.toColumnId,
    required this.toColumnIndex,
    required this.fromColumnId,
    required this.fromColumnIndex,
  });

  void updateFromColumnIndex(int index) {
    if (fromColumnIndex == index) {
      return;
    }
    Log.debug('[$PhantomRecord] Update Column$fromColumnId remove position to $index');
    fromColumnIndex = index;
  }

  void updateInsertedIndex(int index) {
    if (toColumnIndex == index) {
      return;
    }

    Log.debug('[$PhantomRecord] Column$toColumnId update position $toColumnIndex -> $index');
    toColumnIndex = index;
  }

  @override
  String toString() {
    return 'Column$fromColumnId:$fromColumnIndex to Column$toColumnId:$toColumnIndex';
  }
}

class PhantomColumnItem extends ColumnItem {
  final PassthroughPhantomContext phantomContext;

  PhantomColumnItem(PassthroughPhantomContext insertedPhantom) : phantomContext = insertedPhantom;

  @override
  bool get isPhantom => true;

  @override
  String get id => phantomContext.itemData.id;

  Size? get feedbackSize => phantomContext.feedbackSize;

  Widget get draggingWidget =>
      phantomContext.draggingWidget == null ? const SizedBox() : phantomContext.draggingWidget!;
}

class PassthroughPhantomContext extends FakeDragTargetEventTrigger
    with FakeDragTargetEventData, PassthroughPhantomListener {
  @override
  int index;

  @override
  final FlexDragTargetData dragTargetData;

  @override
  Size? get feedbackSize => dragTargetData.state.feedbackSize;

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
