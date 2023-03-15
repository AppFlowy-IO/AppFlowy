import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_data_model.dart';
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
  final GlobalKey _borderKey = GlobalKey();
  bool _borderHovering = false;
  bool _borderDragging = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width:
              context.select((TableData td) => td.getColWidth(widget.colIdx)),
          child: Column(children: _buildCells(context)),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          onEnter: (_) => setState(() => _borderHovering = true),
          onExit: (_) => setState(() => _borderHovering = false),
          child: GestureDetector(
            onHorizontalDragStart: (_) =>
                setState(() => _borderDragging = true),
            onHorizontalDragEnd: (_) => setState(() => _borderDragging = false),
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              RenderBox box =
                  _borderKey.currentContext?.findRenderObject() as RenderBox;
              Offset pos = box.localToGlobal(Offset.zero);
              double colsHeight = context.read<TableData>().colsHeight;
              final int direction = details.delta.dx > 0 ? 1 : -1;
              if ((details.globalPosition.dx - pos.dx - (direction * 90))
                          .abs() >
                      110 ||
                  (details.globalPosition.dy - pos.dy) > colsHeight + 50 ||
                  (details.globalPosition.dy - pos.dy) < -50) {
                return;
              }

              final w = context.read<TableData>().getColWidth(widget.colIdx);
              context
                  .read<TableData>()
                  .setColWidth(widget.colIdx, w + details.delta.dx);
            },
            child: Container(
              key: _borderKey,
              width: 2,
              height: context.select((TableData td) => td.colsHeight),
              color: _borderHovering || _borderDragging
                  ? Colors.blue
                  : Colors.grey,
            ),
          ),
        )
      ],
    );
  }

  List<Widget> _buildCells(BuildContext context) {
    var rowsLen = context.select((TableData td) => td.rowsLen);
    var cells = [];
    final Widget cellBorder = Container(
      height: 2,
      color: Colors.grey,
    );

    for (var i = 0; i < rowsLen; i++) {
      cells.add(
        flowytable.TableCell(
          colIdx: widget.colIdx,
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
