import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/drag_to_reorder/draggable_option_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/columns/simple_columns_block_constant.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class ColumnBlockWidthResizer extends StatefulWidget {
  const ColumnBlockWidthResizer({
    super.key,
    required this.columnNode,
    required this.editorState,
  });

  final Node columnNode;
  final EditorState editorState;

  @override
  State<ColumnBlockWidthResizer> createState() =>
      _ColumnBlockWidthResizerState();
}

class _ColumnBlockWidthResizerState extends State<ColumnBlockWidthResizer> {
  bool isDragging = false;

  ValueNotifier<bool> isHovering = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => isHovering.value = true,
      onExit: (_) {
        // delay the hover state change to avoid flickering
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!isDragging) {
            isHovering.value = false;
          }
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onHorizontalDragCancel: _onHorizontalDragCancel,
        child: ValueListenableBuilder<bool>(
          valueListenable: isHovering,
          builder: (context, isHovering, child) {
            if (isDraggingAppFlowyEditorBlock.value) {
              return SizedBox.shrink();
            }
            return MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: Container(
                width: 2,
                margin: EdgeInsets.symmetric(horizontal: 2),
                color: isHovering
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            );
          },
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
    final width =
        columnNode.attributes[SimpleColumnBlockKeys.width] ?? rect.width;
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
    isHovering.value = false;

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

  void _onHorizontalDragCancel() {
    isDragging = false;
    isHovering.value = false;
  }
}
