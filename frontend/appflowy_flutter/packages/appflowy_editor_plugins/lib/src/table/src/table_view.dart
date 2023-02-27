import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_model.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_cell.dart'
    as flowytable;

class TableView extends StatefulWidget {
  const TableView({
    Key? key,
    required this.data,
    required this.editorState,
    required this.node,
  }) : super(key: key);

  final TableData data;
  final EditorState editorState;
  final Node node;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  final Widget columnBorder = Container(
    height: 100,
    width: 1,
    color: Colors.grey,
  );
  final Widget cellBorder = Container(
    height: 1,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: widget.data,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            width: 225,
            child: Row(
              children: _buildColumns(context),
            ),
          );
        });
  }

  List<Widget> _buildColumns(BuildContext context) {
    var colsLen = context.read<TableData>().colsLen;
    var cols = [];
    for (var i = 0; i < colsLen; i++) {
      cols.add(Container(
        width: 100,
        child: Column(children: _buildCells(context, i)),
      ));
      if (i != colsLen - 1) {
        cols.add(columnBorder);
      }
    }

    return [
      columnBorder,
      ...cols,
      columnBorder,
    ];
  }

  List<Widget> _buildCells(BuildContext context, int colIdx) {
    var colLen = context.read<TableData>().colLen;
    var cells = [];
    for (var i = 0; i < colLen; i++) {
      cells.add(
        flowytable.TableCell(
          colIdx: colIdx,
          rowIdx: i,
          node: widget.node,
          editorState: widget.editorState,
        ),
      );
      if (i != colLen - 1) {
        cells.add(cellBorder);
      }
    }

    return [
      cellBorder,
      ...cells,
      cellBorder,
    ];
  }
}
