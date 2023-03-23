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
  final GlobalKey _borderKey = GlobalKey();
  bool _borderHovering = false;
  bool _borderDragging = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (widget.colIdx == 0) {
      children.add(
        Container(
          width: widget.tableNode.config.tableBorderWidth,
          height: context.select((Node n) => n.attributes['colsHeight']),
          color: Colors.grey,
        ),
      );
    }

    children.addAll([
      SizedBox(
        width: widget.tableNode.getColWidth(widget.colIdx),
        child: Column(children: _buildCells(context)),
      ),
      MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        onEnter: (_) => setState(() => _borderHovering = true),
        onExit: (_) => setState(() => _borderHovering = false),
        child: GestureDetector(
          onHorizontalDragStart: (_) => setState(() => _borderDragging = true),
          onHorizontalDragEnd: (_) => setState(() => _borderDragging = false),
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            RenderBox box =
                _borderKey.currentContext?.findRenderObject() as RenderBox;
            Offset pos = box.localToGlobal(Offset.zero);
            double colsHeight = widget.tableNode.colsHeight;
            final int direction = details.delta.dx > 0 ? 1 : -1;
            if ((details.globalPosition.dx - pos.dx - (direction * 90)).abs() >
                    110 ||
                (details.globalPosition.dy - pos.dy) > colsHeight + 50 ||
                (details.globalPosition.dy - pos.dy) < -50) {
              return;
            }

            final w = widget.tableNode.getColWidth(widget.colIdx);
            widget.tableNode.setColWidth(widget.colIdx, w + details.delta.dx);
          },
          child: Container(
            key: _borderKey,
            width: widget.tableNode.config.tableBorderWidth,
            height: context.select((Node n) => n.attributes['colsHeight']),
            color:
                _borderHovering || _borderDragging ? Colors.blue : Colors.grey,
          ),
        ),
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
