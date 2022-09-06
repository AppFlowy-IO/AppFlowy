import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/widgets.dart';

import '../../utils/log.dart';
import '../reorder_flex/drag_state.dart';
import '../reorder_flex/drag_target.dart';
import '../reorder_flex/drag_target_interceptor.dart';
import 'phantom_state.dart';

abstract class BoardPhantomControllerDelegate {
  AFBoardGroupDataController? controller(String groupId);

  bool removePhantom(String groupId);

  /// Insert the phantom into the group
  ///
  /// * [groupId] id of the group
  /// * [phantomIndex] the phantom occupies index
  void insertPhantom(
    String groupId,
    int index,
    PhantomGroupItem item,
  );

  /// Update the group's phantom index if it exists.
  /// [toGroupId] the id of the group
  /// [dragTargetIndex] the index of the dragTarget
  void updatePhantom(String groupId, int newIndex);

  void moveGroupItemToAnotherGroup(
    String fromGroupId,
    int fromGroupIndex,
    String toGroupId,
    int toGroupIndex,
  );
}

class BoardPhantomController extends OverlapDragTargetDelegate
    with CrossReorderFlexDragTargetDelegate {
  PhantomRecord? phantomRecord;
  final BoardPhantomControllerDelegate delegate;
  final BoardGroupsState groupsState;
  final phantomState = GroupPhantomState();
  BoardPhantomController({
    required this.delegate,
    required this.groupsState,
  });

  bool isFromGroup(String groupId) {
    if (phantomRecord != null) {
      return phantomRecord!.fromGroupId == groupId;
    } else {
      return true;
    }
  }

  void transformIndex(int fromIndex, int toIndex) {
    if (phantomRecord == null) {
      return;
    }
    assert(phantomRecord!.fromGroupIndex == fromIndex);
    phantomRecord?.updateFromGroupIndex(toIndex);
  }

  void groupStartDragging(String groupId) {
    phantomState.setGroupIsDragging(groupId, true);
  }

  /// Remove the phantom in the group when the group is end dragging.
  void groupEndDragging(String groupId) {
    phantomState.setGroupIsDragging(groupId, false);

    if (phantomRecord == null) return;

    final fromGroupId = phantomRecord!.fromGroupId;
    final toGroupId = phantomRecord!.toGroupId;
    if (fromGroupId == groupId) {
      phantomState.notifyDidRemovePhantom(toGroupId);
    }

    if (phantomRecord!.toGroupId == groupId) {
      delegate.moveGroupItemToAnotherGroup(
        fromGroupId,
        phantomRecord!.fromGroupIndex,
        toGroupId,
        phantomRecord!.toGroupIndex,
      );

      // Log.debug(
      //     "[$BoardPhantomController] did move ${phantomRecord.toString()}");
      phantomRecord = null;
    }
  }

  /// Remove the phantom in the group if it contains phantom
  void _removePhantom(String groupId) {
    if (delegate.removePhantom(groupId)) {
      phantomState.notifyDidRemovePhantom(groupId);
      phantomState.removeGroupListener(groupId);
    }
  }

  void _insertPhantom(
    String toGroupId,
    FlexDragTargetData dragTargetData,
    int phantomIndex,
  ) {
    final phantomContext = PassthroughPhantomContext(
      index: phantomIndex,
      dragTargetData: dragTargetData,
    );
    phantomState.addGroupListener(toGroupId, phantomContext);

    delegate.insertPhantom(
      toGroupId,
      phantomIndex,
      PhantomGroupItem(phantomContext),
    );

    phantomState.notifyDidInsertPhantom(toGroupId, phantomIndex);
  }

  /// Reset or initial the [PhantomRecord]
  ///
  ///
  /// * [groupId] the id of the group
  /// * [dragTargetData]
  /// * [dragTargetIndex]
  ///
  void _resetPhantomRecord(
    String groupId,
    FlexDragTargetData dragTargetData,
    int dragTargetIndex,
  ) {
    // Log.debug(
    //     '[$BoardPhantomController] move Group:[${dragTargetData.reorderFlexId}]:${dragTargetData.draggingIndex} '
    //     'to Group:[$groupId]:$dragTargetIndex');

    phantomRecord = PhantomRecord(
      toGroupId: groupId,
      toGroupIndex: dragTargetIndex,
      fromGroupId: dragTargetData.reorderFlexId,
      fromGroupIndex: dragTargetData.draggingIndex,
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

      return true;
    }

    final isNewDragTarget = phantomRecord!.toGroupId != reorderFlexId;
    if (isNewDragTarget) {
      /// Remove the phantom when the dragTarget is moved from one group to another group.
      _removePhantom(phantomRecord!.toGroupId);
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
    if (phantomRecord!.toGroupId == reorderFlexId) {
      /// Update the existing phantom index
      delegate.updatePhantom(phantomRecord!.toGroupId, dragTargetIndex);
    }
  }

  @override
  void cancel() {
    if (phantomRecord == null) {
      return;
    }

    /// Remove the phantom when the dragTarge is go back to the original group.
    _removePhantom(phantomRecord!.toGroupId);
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
  int getInsertedIndex(String dragTargetId) {
    if (phantomState.isDragging(dragTargetId)) {
      return -1;
    }

    final controller = delegate.controller(dragTargetId);
    if (controller != null) {
      return controller.groupData.items.length;
    } else {
      return 0;
    }
  }
}

/// Use [PhantomRecord] to record where to remove the group item and where to
/// insert the group item.
///
/// [fromGroupId] the group that phantom comes from
/// [fromGroupIndex] the index of the phantom from the original group
/// [toGroupId] the group that the phantom moves into
/// [toGroupIndex] the index of the phantom moves into the group
///
class PhantomRecord {
  final String fromGroupId;
  int fromGroupIndex;

  final String toGroupId;
  int toGroupIndex;

  PhantomRecord({
    required this.toGroupId,
    required this.toGroupIndex,
    required this.fromGroupId,
    required this.fromGroupIndex,
  });

  void updateFromGroupIndex(int index) {
    if (fromGroupIndex == index) {
      return;
    }

    fromGroupIndex = index;
  }

  void updateInsertedIndex(int index) {
    if (toGroupIndex == index) {
      return;
    }

    Log.debug(
        '[$PhantomRecord] Group:[$toGroupId] update position $toGroupIndex -> $index');
    toGroupIndex = index;
  }

  @override
  String toString() {
    return 'Group:[$fromGroupId]:$fromGroupIndex to Group:[$toGroupId]:$toGroupIndex';
  }
}

class PhantomGroupItem extends AppFlowyGroupItem {
  final PassthroughPhantomContext phantomContext;

  PhantomGroupItem(PassthroughPhantomContext insertedPhantom)
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

  AppFlowyGroupItem get itemData =>
      dragTargetData.reorderFlexItem as AppFlowyGroupItem;

  @override
  void Function(int?)? onInserted;

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
  void fakeOnDragStart(void Function(int? index) callback) {
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
  PhantomDraggableBuilder();
  @override
  Widget? build<T extends DragTargetData>(
    BuildContext context,
    Widget child,
    DragTargetOnStarted onDragStarted,
    DragTargetOnEnded<T> onDragEnded,
    DragTargetWillAccepted<T> onWillAccept,
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
