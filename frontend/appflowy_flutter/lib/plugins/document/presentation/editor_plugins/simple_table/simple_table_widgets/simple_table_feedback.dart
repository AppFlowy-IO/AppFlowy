import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableFeedback extends StatefulWidget {
  const SimpleTableFeedback({
    super.key,
    required this.editorState,
    required this.node,
    required this.type,
    required this.index,
  });

  /// The node of the table.
  /// Its type must be one of the following:
  ///   [SimpleTableBlockKeys.type], [SimpleTableRowBlockKeys.type], [SimpleTableCellBlockKeys.type].
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

    assert(
      [
        SimpleTableBlockKeys.type,
        SimpleTableRowBlockKeys.type,
        SimpleTableCellBlockKeys.type,
      ].contains(widget.node.type),
      'The node type must be one of the following: '
      '[SimpleTableBlockKeys.type], [SimpleTableRowBlockKeys.type], [SimpleTableCellBlockKeys.type].',
    );

    simpleTableContext.isSelectingTable.value = true;
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
    return Provider.value(
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
    final tableNode = widget.node.parentTableNode?.deepCopy();
    if (tableNode == null) {
      return simpleTableBlockNode(children: []);
    }

    switch (widget.type) {
      case SimpleTableMoreActionType.row:
        if (widget.index >= tableNode.rowLength || widget.index < 0) {
          return simpleTableBlockNode(children: []);
        }

        final row = tableNode.children[widget.index];
        return tableNode.copyWith(
          children: [row],
          attributes: {
            ...tableNode.attributes,
            if (widget.index != 0) SimpleTableBlockKeys.enableHeaderRow: false,
          },
        );
      case SimpleTableMoreActionType.column:
        if (widget.index >= tableNode.columnLength || widget.index < 0) {
          return simpleTableBlockNode(children: []);
        }

        final rows = tableNode.children.map((row) {
          final cell = row.children[widget.index];
          return simpleTableRowBlockNode(children: [cell]);
        }).toList();

        return tableNode.copyWith(
          children: rows,
          attributes: {
            ...tableNode.attributes,
            if (widget.index != 0)
              SimpleTableBlockKeys.enableHeaderColumn: false,
          },
        );
    }
  }
}
