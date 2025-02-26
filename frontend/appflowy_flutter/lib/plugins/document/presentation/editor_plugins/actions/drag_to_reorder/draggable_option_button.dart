import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/drag_to_reorder/util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/drag_to_reorder/visual_drag_area.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';

import 'draggable_option_button_feedback.dart';
import 'option_button.dart';

// this flag is used to disable the tooltip of the block when it is dragged
@visibleForTesting
ValueNotifier<bool> isDraggingAppFlowyEditorBlock = ValueNotifier(false);

class DraggableOptionButton extends StatefulWidget {
  const DraggableOptionButton({
    super.key,
    required this.controller,
    required this.editorState,
    required this.blockComponentContext,
    required this.blockComponentBuilder,
  });

  final PopoverController controller;
  final EditorState editorState;
  final BlockComponentContext blockComponentContext;
  final Map<String, BlockComponentBuilder> blockComponentBuilder;

  @override
  State<DraggableOptionButton> createState() => _DraggableOptionButtonState();
}

class _DraggableOptionButtonState extends State<DraggableOptionButton> {
  late Node node;
  late BlockComponentContext blockComponentContext;

  Offset? globalPosition;

  @override
  void initState() {
    super.initState();

    // copy the node to avoid the node in document being updated
    node = widget.blockComponentContext.node.deepCopy();
  }

  @override
  void dispose() {
    node.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<Node>(
      data: node,
      onDragStarted: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      feedback: DraggleOptionButtonFeedback(
        controller: widget.controller,
        editorState: widget.editorState,
        blockComponentContext: widget.blockComponentContext,
        blockComponentBuilder: widget.blockComponentBuilder,
      ),
      child: OptionButton(
        isDragging: isDraggingAppFlowyEditorBlock,
        controller: widget.controller,
        editorState: widget.editorState,
        blockComponentContext: widget.blockComponentContext,
      ),
    );
  }

  void _onDragStart() {
    EditorNotification.dragStart().post();
    isDraggingAppFlowyEditorBlock.value = true;
    widget.editorState.selectionService.removeDropTarget();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    isDraggingAppFlowyEditorBlock.value = true;

    final offset = details.globalPosition;

    widget.editorState.selectionService.renderDropTargetForOffset(
      offset,
      interceptor: (context, targetNode) {
        // if the cursor node is in a columns block or a column block,
        //  we will return the node's parent instead to support dragging a node to the inside of a columns block or a column block.
        final parentColumnNode = targetNode.parentColumn;
        if (parentColumnNode != null) {
          final position = getDragAreaPosition(
            context,
            targetNode,
            offset,
          );

          if (position != null && position.$2 == HorizontalPosition.right) {
            return parentColumnNode;
          }
        }

        return targetNode;
      },
      builder: (context, data) {
        return VisualDragArea(
          editorState: widget.editorState,
          data: data,
          dragNode: widget.blockComponentContext.node,
        );
      },
    );

    globalPosition = details.globalPosition;

    // auto scroll the page when the drag position is at the edge of the screen
    widget.editorState.scrollService?.startAutoScroll(
      details.localPosition,
    );
  }

  void _onDragEnd(DraggableDetails details) {
    isDraggingAppFlowyEditorBlock.value = false;

    widget.editorState.selectionService.removeDropTarget();

    if (globalPosition == null) {
      return;
    }

    final data = widget.editorState.selectionService.getDropTargetRenderData(
      globalPosition!,
      interceptor: (context, targetNode) {
        // if the cursor node is in a columns block or a column block,
        //  we will return the node's parent instead to support dragging a node to the inside of a columns block or a column block.
        final parentColumnNode = targetNode.parentColumn;
        if (parentColumnNode != null) {
          final position = getDragAreaPosition(
            context,
            targetNode,
            globalPosition!,
          );

          if (position != null && position.$2 == HorizontalPosition.right) {
            return parentColumnNode;
          }
        }

        return targetNode;
      },
    );
    dragToMoveNode(
      context,
      node: widget.blockComponentContext.node,
      acceptedPath: data?.cursorNode?.path,
      dragOffset: globalPosition!,
    ).then((_) {
      EditorNotification.dragEnd().post();
    });
  }
}
