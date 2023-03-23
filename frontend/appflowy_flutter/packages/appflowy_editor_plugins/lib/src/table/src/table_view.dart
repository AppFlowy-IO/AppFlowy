import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_action_button.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_col.dart';

class TableView extends StatefulWidget {
  const TableView({
    Key? key,
    required this.editorState,
    required this.tableNode,
  }) : super(key: key);

  final EditorState editorState;
  final TableNode tableNode;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Row(
              children: [
                ..._buildColumns(context),
                TableActionButton(
                  padding: const EdgeInsets.only(left: 1),
                  width: 35,
                  height: widget.tableNode.colsHeight,
                  onPressed: () {
                    final transaction = widget.editorState.transaction;
                    widget.tableNode.addCol(transaction);
                    widget.editorState.apply(transaction);
                  },
                ),
              ],
            ),
            TableActionButton(
              padding: const EdgeInsets.only(top: 1, right: 32),
              height: 35,
              width: widget.tableNode.tableWidth,
              onPressed: () {
                final transaction = widget.editorState.transaction;
                widget.tableNode.addRow(transaction);
                widget.editorState.apply(transaction);
              },
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildColumns(BuildContext context) {
    return List.generate(
      widget.tableNode.colsLen,
      (i) => TableCol(
        colIdx: i,
        editorState: widget.editorState,
        tableNode: widget.tableNode,
      ),
    );
  }
}
