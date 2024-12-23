import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_widgets/simple_table_feedback.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class SimpleTableDraggableReorderButton extends StatelessWidget {
  const SimpleTableDraggableReorderButton({
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
      child: SimpleTableReorderButton(
        isShowingMenu: isShowingMenu,
        type: type,
      ),
    );
  }

  void _startDragging() {
    switch (type) {
      case SimpleTableMoreActionType.column:
        simpleTableContext.isReorderingColumn.value = (true, index);
        break;
      case SimpleTableMoreActionType.row:
        simpleTableContext.isReorderingRow.value = (true, index);
        break;
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

class SimpleTableReorderButton extends StatelessWidget {
  const SimpleTableReorderButton({
    super.key,
    required this.isShowingMenu,
    required this.type,
  });

  final ValueNotifier<bool> isShowingMenu;
  final SimpleTableMoreActionType type;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isShowingMenu,
      builder: (context, isShowingMenu, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: isShowingMenu
                  ? context.simpleTableMoreActionHoverColor
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: context.simpleTableMoreActionBorderColor,
              ),
            ),
            height: 16.0,
            width: 16.0,
            child: FlowySvg(
              type.reorderIconSvg,
              color: isShowingMenu ? Colors.white : null,
              size: const Size.square(16.0),
            ),
          ),
        );
      },
    );
  }
}
