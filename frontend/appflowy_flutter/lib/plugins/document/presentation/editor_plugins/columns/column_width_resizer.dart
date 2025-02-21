import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class ColumnWidthResizer extends StatefulWidget {
  const ColumnWidthResizer({
    super.key,
    required this.columnNode,
    required this.editorState,
  });

  final Node columnNode;
  final EditorState editorState;

  @override
  State<ColumnWidthResizer> createState() => _ColumnWidthResizerState();
}

class _ColumnWidthResizerState extends State<ColumnWidthResizer> {
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: Container(
          width: SimpleColumnsBlockConstants.columnWidthResizerWidth,
          color: SimpleColumnsBlockConstants.columnWidthResizerColor,
        ),
      ),
    );
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!isDragging) {
      return;
    }

    // update the column width in memory
    final columnNode = widget.columnNode;
    final rect = columnNode.rect;
    final width = columnNode.attributes[SimpleColumnBlockKeys.width] ?? rect.width;
    final newWidth = width + details.delta.dx;
    final transaction = widget.editorState.transaction;
    transaction.updateNode(columnNode, {
      ...columnNode.attributes,
      SimpleColumnBlockKeys.width: newWidth.clamp(
        SimpleColumnsBlockConstants.minimumColumnWidth,
        double.infinity,
      ),
    });
    final columnsNode = columnNode.parent;
    if (columnsNode != null) {
      transaction.updateNode(columnsNode, {
        ...columnsNode.attributes,
        ColumnsBlockKeys.columnCount: columnsNode.children.length,
      });
    }
    widget.editorState.apply(
      transaction,
      options: ApplyOptions(inMemoryUpdate: true),
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!isDragging) {
      return;
    }

    // apply the transaction again to make sure the width is updated
    final transaction = widget.editorState.transaction;
    transaction.updateNode(widget.columnNode, {
      ...widget.columnNode.attributes,
    });
    widget.editorState.apply(transaction);

    isDragging = false;
  }
}
