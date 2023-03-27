import 'package:appflowy_editor_plugins/src/table/src/table_col_border.dart';
import 'package:appflowy_editor_plugins/src/table/src/util.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:provider/provider.dart';

class TableCol extends StatefulWidget {
  const TableCol({
    Key? key,
    required this.tableNode,
    required this.editorState,
    required this.colIdx,
  }) : super(key: key);

  final int colIdx;
  final EditorState editorState;
  final TableNode tableNode;

  @override
  State<TableCol> createState() => _TableColState();
}

class _TableColState extends State<TableCol> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (widget.colIdx == 0) {
      children.add(TableColBorder(
        resizable: false,
        tableNode: widget.tableNode,
        colIdx: widget.colIdx,
      ));
    }

    children.addAll([
      SizedBox(
        width: context.select(
            (Node n) => getCellNode(n, widget.colIdx, 0)?.attributes['width']),
        child: Column(children: _buildCells(context)),
      ),
      TableColBorder(
        resizable: true,
        tableNode: widget.tableNode,
        colIdx: widget.colIdx,
      )
    ]);

    return Row(children: children);
  }

  List<Widget> _buildCells(BuildContext context) {
    var rowsLen = widget.tableNode.rowsLen;
    var cells = [];
    final Widget cellBorder = Container(
      height: widget.tableNode.config.tableBorderWidth,
      color: Colors.grey,
    );

    for (var i = 0; i < rowsLen; i++) {
      final node = widget.tableNode.getCell(widget.colIdx, i);

      updateRowHeightCallback(i);
      node.addListener(() => updateRowHeightCallback(i));
      node.children.first.addListener(() => updateRowHeightCallback(i));

      cells.addAll([
        widget.editorState.service.renderPluginService.buildPluginWidget(
          NodeWidgetContext<Node>(
            context: context,
            node: node,
            editorState: widget.editorState,
          ),
        ),
        cellBorder
      ]);
    }

    return [
      cellBorder,
      ...cells,
    ];
  }

  updateRowHeightCallback(int row) => WidgetsBinding.instance
      .addPostFrameCallback((_) => widget.tableNode.updateRowHeight(row));
}
