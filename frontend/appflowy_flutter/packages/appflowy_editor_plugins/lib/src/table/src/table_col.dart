import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_cell.dart'
    as flowytable;

class TableCol extends StatefulWidget {
  const TableCol({
    Key? key,
    required this.colIdx,
    required this.editorState,
    required this.node,
  }) : super(key: key);

  final int colIdx;
  final EditorState editorState;
  final Node node;

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
            flowytable.TableCell(
              colIdx: widget.colIdx,
              rowIdx: 0,
              editorState: widget.editorState,
              node: widget.node,
            ),
            Container(
              height: 1,
              color: Colors.grey,
            ),
            flowytable.TableCell(
              colIdx: widget.colIdx,
              rowIdx: 1,
              editorState: widget.editorState,
              node: widget.node,
            ),
            Container(
              height: 1,
              color: Colors.grey,
            ),
          ],
        ));
  }
}
