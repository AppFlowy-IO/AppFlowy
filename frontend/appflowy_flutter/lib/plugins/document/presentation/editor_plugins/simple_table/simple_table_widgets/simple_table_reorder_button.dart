import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_widgets/simple_table_widget.dart';
import 'package:appflowy/util/throttle.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final Throttler throttler =
    Throttler(duration: const Duration(milliseconds: 100));

class SimpleTableDraggableReorderButton extends StatelessWidget {
  const SimpleTableDraggableReorderButton({
    super.key,
    required this.node,
    required this.index,
    required this.isShowingMenu,
    required this.type,
    required this.editorState,
    required this.simpleTableContext,
    required this.onTap,
  });

  final Node node;
  final int index;
  final ValueNotifier<bool> isShowingMenu;
  final SimpleTableMoreActionType type;
  final EditorState editorState;
  final SimpleTableContext simpleTableContext;
  final VoidCallback onTap;

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

class SimpleTableFeedback extends StatefulWidget {
  const SimpleTableFeedback({
    super.key,
    required this.editorState,
    required this.node,
    required this.type,
    required this.index,
  });

  /// The node of the table.
  /// Its type must be [SimpleTableBlockKeys.type].
  final Node node;

  /// The type of the more action.
  ///
  /// If the type is [SimpleTableMoreActionType.column], the feedback will use index as column index.
  /// If the type is [SimpleTableMoreActionType.row], the feedback will use index as row index.
  final SimpleTableMoreActionType type;

  /// The index of the column or row.
  final int index;

  final EditorState editorState;

  @override
  State<SimpleTableFeedback> createState() => _SimpleTableFeedbackState();
}

class _SimpleTableFeedbackState extends State<SimpleTableFeedback> {
  final simpleTableContext = SimpleTableContext();
  late final Node dummyNode;

  @override
  void initState() {
    super.initState();

    dummyNode = _buildDummyNode();
  }

  @override
  void dispose() {
    simpleTableContext.dispose();
    dummyNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.withOpacity(0.2),
      width: 200,
      height: 400,
      alignment: Alignment.center,
      child: Provider.value(
        value: widget.editorState,
        child: SimpleTableWidget(
          node: dummyNode,
          simpleTableContext: simpleTableContext,
          enableAddColumnButton: false,
          enableAddRowButton: false,
          enableAddColumnAndRowButton: false,
          enableHoverEffect: false,
          isFeedback: true,
        ),
      ),
    );
  }

  /// Build the dummy node for the feedback.
  ///
  /// For example,
  ///
  /// If the type is [SimpleTableMoreActionType.row], we should build the dummy table node using the data from the first row of the table node.
  /// If the type is [SimpleTableMoreActionType.column], we should build the dummy table node using the data from the first column of the table node.
  Node _buildDummyNode() {
    // deep copy the table node to avoid mutating the original node
    final tableNode = widget.node.copyWith();

    switch (widget.type) {
      case SimpleTableMoreActionType.row:
        if (widget.index >= tableNode.rowLength || widget.index < 0) {
          return simpleTableBlockNode(children: []);
        }

        final row = tableNode.children[widget.index];
        return simpleTableBlockNode(children: [row]);

      case SimpleTableMoreActionType.column:
        if (widget.index >= tableNode.columnLength || widget.index < 0) {
          return simpleTableBlockNode(children: []);
        }

        final rows = tableNode.children.map((row) {
          final cell = row.children[widget.index];
          return simpleTableRowBlockNode(children: [cell]);
        }).toList();
        return simpleTableBlockNode(children: rows);
    }
  }
}
