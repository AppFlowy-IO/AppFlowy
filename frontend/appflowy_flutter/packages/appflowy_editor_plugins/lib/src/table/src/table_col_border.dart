import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:provider/provider.dart';

class TableColBorder extends StatefulWidget {
  const TableColBorder({
    Key? key,
    required this.tableNode,
    required this.colIdx,
    required this.resizable,
  }) : super(key: key);

  final bool resizable;
  final int colIdx;
  final TableNode tableNode;

  @override
  State<TableColBorder> createState() => _TableColBorderState();
}

class _TableColBorderState extends State<TableColBorder> {
  final GlobalKey _borderKey = GlobalKey();
  bool _borderHovering = false;
  bool _borderDragging = false;

  @override
  Widget build(BuildContext context) {
    if (widget.resizable) {
      return buildResizableBorder(context);
    }
    return buildFixedBorder(context);
  }

  buildResizableBorder(BuildContext context) {
    return MouseRegion(
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
          color: _borderHovering || _borderDragging ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  buildFixedBorder(BuildContext context) {
    return Container(
      width: widget.tableNode.config.tableBorderWidth,
      height: context.select((Node n) => n.attributes['colsHeight']),
      color: Colors.grey,
    );
  }
}
