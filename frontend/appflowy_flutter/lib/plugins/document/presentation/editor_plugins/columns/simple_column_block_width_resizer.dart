import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/drag_to_reorder/draggable_option_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class SimpleColumnBlockWidthResizer extends StatefulWidget {
  const SimpleColumnBlockWidthResizer({
    super.key,
    required this.columnNode,
    required this.editorState,
  });

  final Node columnNode;
  final EditorState editorState;

  @override
  State<SimpleColumnBlockWidthResizer> createState() =>
      _SimpleColumnBlockWidthResizerState();
}

class _SimpleColumnBlockWidthResizerState
    extends State<SimpleColumnBlockWidthResizer> {
  bool isDragging = false;

  ValueNotifier<bool> isHovering = ValueNotifier(false);

  @override
  void dispose() {
    isHovering.dispose();

    super.dispose();
  }

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
    EditorGlobalConfiguration.enableDragMenu.value = false;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!isDragging) {
      return;
    }

    // update the column width in memory
    final columnNode = widget.columnNode;
    final columnsNode = columnNode.columnsParent;
    if (columnsNode == null) {
      return;
    }
    final editorWidth = columnsNode.rect.width;
    final rect = columnNode.rect;
    final width = rect.width;
    final originalRatio = columnNode.attributes[SimpleColumnBlockKeys.ratio];
    final newWidth = width + details.delta.dx;

    final transaction = widget.editorState.transaction;
    final newRatio = newWidth / editorWidth;
    transaction.updateNode(columnNode, {
      ...columnNode.attributes,
      SimpleColumnBlockKeys.ratio: newRatio,
    });

    if (newRatio < 0.1 && newRatio < originalRatio) {
      return;
    }

    final nextColumn = columnNode.nextColumn;
    if (nextColumn != null) {
      final nextColumnRect = nextColumn.rect;
      final nextColumnWidth = nextColumnRect.width;
      final newNextColumnWidth = nextColumnWidth - details.delta.dx;
      final newNextColumnRatio = newNextColumnWidth / editorWidth;
      if (newNextColumnRatio < 0.1) {
        return;
      }
      transaction.updateNode(nextColumn, {
        ...nextColumn.attributes,
        SimpleColumnBlockKeys.ratio: newNextColumnRatio,
      });
    }

    transaction.updateNode(columnsNode, {
      ...columnsNode.attributes,
      ColumnsBlockKeys.columnCount: columnsNode.children.length,
    });

    widget.editorState.apply(
      transaction,
      options: ApplyOptions(inMemoryUpdate: true),
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    isHovering.value = false;
    EditorGlobalConfiguration.enableDragMenu.value = true;

    if (!isDragging) {
      return;
    }

    // apply the transaction again to make sure the width is updated
    final transaction = widget.editorState.transaction;
    final columnsNode = widget.columnNode.columnsParent;
    if (columnsNode == null) {
      return;
    }
    for (final columnNode in columnsNode.children) {
      transaction.updateNode(columnNode, {
        ...columnNode.attributes,
      });
    }
    widget.editorState.apply(transaction);

    isDragging = false;
  }

  void _onHorizontalDragCancel() {
    isDragging = false;
    isHovering.value = false;
    EditorGlobalConfiguration.enableDragMenu.value = true;
  }
}
