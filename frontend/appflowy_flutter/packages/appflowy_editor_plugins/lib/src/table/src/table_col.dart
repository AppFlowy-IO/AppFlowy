import 'package:flutter/material.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_cell.dart'
    as flowytable;

class TableCol extends StatefulWidget {
  const TableCol({Key? key, required this.colIdx}) : super(key: key);

  final int colIdx;

  @override
  State<TableCol> createState() => _TableColState();
}

class _TableColState extends State<TableCol> {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 100,
        child: Column(
          children: [
            Container(
              height: 1,
              color: Colors.grey,
            ),
            flowytable.TableCell(colIdx: widget.colIdx, rowIdx: 0),
            Container(
              height: 1,
              color: Colors.grey,
            ),
            flowytable.TableCell(colIdx: widget.colIdx, rowIdx: 1),
            Container(
              height: 1,
              color: Colors.grey,
            ),
          ],
        ));
  }
}
