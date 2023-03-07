import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_data_model.dart';
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
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: widget.data,
        builder: (context, _) {
          return Container(
            padding:
                const EdgeInsets.only(left: 0, bottom: 8, right: 80, top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildColumns(context),
            ),
          );
        });
  }

  List<Widget> _buildColumns(BuildContext context) {
    var colsLen = context.read<TableData>().colsLen;
    var cols = [];

    final Widget columnBorder = MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: Container(
        width: 2,
        height: context.select((TableData td) => td.colsHeight) + 6,
        color: Colors.grey,
      ),
    );

    for (var i = 0; i < colsLen; i++) {
      cols.add(
        SizedBox(
          width: 80,
          child: Column(children: _buildColumn(context, i)),
        ),
      );
      cols.add(columnBorder);
    }

    return [
      columnBorder,
      ...cols,
    ];
  }

  List<Widget> _buildColumn(BuildContext context, int colIdx) {
    var rowsLen = context.read<TableData>().rowsLen;
    var cells = [];
    final Widget cellBorder = MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: Container(
        height: 2,
        color: Colors.grey,
      ),
    );

    for (var i = 0; i < rowsLen; i++) {
      cells.add(
        flowytable.TableCell(
          colIdx: colIdx,
          rowIdx: i,
          node: widget.node,
          editorState: widget.editorState,
        ),
      );
      cells.add(cellBorder);
    }

    return [
      cellBorder,
      ...cells,
    ];
  }
}
