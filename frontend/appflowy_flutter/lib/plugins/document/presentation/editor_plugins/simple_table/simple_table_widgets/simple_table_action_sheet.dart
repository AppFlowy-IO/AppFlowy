import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_widgets/simple_table_feedback.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableMobileDraggableReorderButton extends StatelessWidget {
  const SimpleTableMobileDraggableReorderButton({
    super.key,
    required this.node,
    required this.index,
    required this.isShowingMenu,
    required this.type,
    required this.editorState,
    required this.simpleTableContext,
  });

  final Node node;
  final int index;
  final ValueNotifier<bool> isShowingMenu;
  final SimpleTableMoreActionType type;
  final EditorState editorState;
  final SimpleTableContext simpleTableContext;

  @override
  Widget build(BuildContext context) {
    return Draggable<int>(
      data: index,
      onDragStarted: () => _startDragging(),
      onDragUpdate: (details) => _onDragUpdate(details),
      onDragEnd: (_) => _stopDragging(),
      feedback: SimpleTableFeedback(
        editorState: editorState,
        node: node,
        type: type,
        index: index,
      ),
      child: SimpleTableMobileReorderButton(
        index: index,
        type: type,
        node: node,
        isShowingMenu: isShowingMenu,
      ),
    );
  }

  void _startDragging() {
    editorState.selection = null;

    switch (type) {
      case SimpleTableMoreActionType.column:
        simpleTableContext.isReorderingColumn.value = (true, index);

      case SimpleTableMoreActionType.row:
        simpleTableContext.isReorderingRow.value = (true, index);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    simpleTableContext.reorderingOffset.value = details.globalPosition;
  }

  void _stopDragging() {
    switch (type) {
      case SimpleTableMoreActionType.column:
        _reorderColumn();
      case SimpleTableMoreActionType.row:
        _reorderRow();
    }

    simpleTableContext.reorderingOffset.value = Offset.zero;
    switch (type) {
      case SimpleTableMoreActionType.column:
        simpleTableContext.isReorderingColumn.value = (false, -1);
        break;
      case SimpleTableMoreActionType.row:
        simpleTableContext.isReorderingRow.value = (false, -1);
        break;
    }
  }

  void _reorderColumn() {
    final fromIndex = simpleTableContext.isReorderingColumn.value.$2;
    final toIndex = simpleTableContext.hoveringTableCell.value?.columnIndex;
    if (toIndex == null) {
      return;
    }

    editorState.reorderColumn(
      node,
      fromIndex: fromIndex,
      toIndex: toIndex,
    );
  }

  void _reorderRow() {
    final fromIndex = simpleTableContext.isReorderingRow.value.$2;
    final toIndex = simpleTableContext.hoveringTableCell.value?.rowIndex;
    if (toIndex == null) {
      return;
    }

    editorState.reorderRow(
      node,
      fromIndex: fromIndex,
      toIndex: toIndex,
    );
  }
}

class SimpleTableMobileReorderButton extends StatefulWidget {
  const SimpleTableMobileReorderButton({
    super.key,
    required this.index,
    required this.type,
    required this.node,
    required this.isShowingMenu,
  });

  final int index;
  final SimpleTableMoreActionType type;
  final Node node;
  final ValueNotifier<bool> isShowingMenu;

  @override
  State<SimpleTableMobileReorderButton> createState() =>
      _SimpleTableMobileReorderButtonState();
}

class _SimpleTableMobileReorderButtonState
    extends State<SimpleTableMobileReorderButton> {
  late final EditorState editorState = context.read<EditorState>();
  late final SimpleTableContext simpleTableContext =
      context.read<SimpleTableContext>();

  @override
  void initState() {
    super.initState();

    simpleTableContext.selectingRow.addListener(_onUpdateShowingMenu);
    simpleTableContext.selectingColumn.addListener(_onUpdateShowingMenu);
  }

  @override
  void dispose() {
    simpleTableContext.selectingRow.removeListener(_onUpdateShowingMenu);
    simpleTableContext.selectingColumn.removeListener(_onUpdateShowingMenu);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async => _onSelecting(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: widget.type == SimpleTableMoreActionType.column
            ? SimpleTableConstants.columnActionSheetHitTestAreaHeight
            : null,
        width: widget.type == SimpleTableMoreActionType.row
            ? SimpleTableConstants.rowActionSheetHitTestAreaWidth
            : null,
        child: Align(
          child: SimpleTableReorderButton(
            isShowingMenu: widget.isShowingMenu,
            type: widget.type,
          ),
        ),
      ),
    );
  }

  Future<void> _onSelecting() async {
    widget.isShowingMenu.value = true;

    // update the selecting row or column
    switch (widget.type) {
      case SimpleTableMoreActionType.column:
        simpleTableContext.selectingColumn.value = widget.index;
        simpleTableContext.selectingRow.value = null;
        break;
      case SimpleTableMoreActionType.row:
        simpleTableContext.selectingRow.value = widget.index;
        simpleTableContext.selectingColumn.value = null;
    }

    editorState.selection = null;

    // show the bottom sheet
    await showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      builder: (context) => Provider.value(
        value: simpleTableContext,
        child: SimpleTableCellBottomSheet(
          type: widget.type,
          cellNode: widget.node,
          editorState: editorState,
        ),
      ),
    );

    // reset the selecting row or column
    simpleTableContext.selectingRow.value = null;
    simpleTableContext.selectingColumn.value = null;

    widget.isShowingMenu.value = false;
  }

  void _onUpdateShowingMenu() {
    // highlight the reorder button when the row or column is selected
    final selectingRow = simpleTableContext.selectingRow.value;
    final selectingColumn = simpleTableContext.selectingColumn.value;

    if (selectingRow == widget.index &&
        widget.type == SimpleTableMoreActionType.row) {
      widget.isShowingMenu.value = true;
    } else if (selectingColumn == widget.index &&
        widget.type == SimpleTableMoreActionType.column) {
      widget.isShowingMenu.value = true;
    } else {
      widget.isShowingMenu.value = false;
    }
  }
}
