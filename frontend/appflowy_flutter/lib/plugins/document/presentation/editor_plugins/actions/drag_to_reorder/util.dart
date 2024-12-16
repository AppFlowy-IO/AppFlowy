import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum HorizontalPosition { left, center, right }

enum VerticalPosition { top, middle, bottom }

Future<void> dragToMoveNode(
  BuildContext context, {
  required Node node,
  required Offset dragOffset,
  Path? acceptedPath,
}) async {
  if (acceptedPath == null) {
    Log.info('acceptedPath is null');
    return;
  }

  final editorState = context.read<EditorState>();
  final targetNode = editorState.getNodeAtPath(acceptedPath);
  if (targetNode == null) {
    Log.info('targetNode is null');
    return;
  }

  final position = getDragAreaPosition(context, targetNode, dragOffset);
  if (position == null) {
    Log.info('position is null');
    return;
  }

  final (verticalPosition, horizontalPosition, _) = position;
  Path newPath = targetNode.path;

  // Determine the new path based on drop position
  // For VerticalPosition.top, we keep the target node's path
  if (verticalPosition == VerticalPosition.bottom) {
    if (horizontalPosition == HorizontalPosition.left) {
      newPath = newPath.next;
      final node = editorState.document.nodeAtPath(newPath);
      if (node == null) {
        // if node is null, it means the node is the last one of the document.
        newPath = targetNode.path;
      }
    } else {
      newPath = newPath.child(0);
    }
  }

  // Check if the drop should be ignored
  if (shouldIgnoreDragTarget(
    editorState: editorState,
    dragNode: node,
    targetPath: newPath,
  )) {
    Log.info(
      'Drop ignored: node($node, ${node.path}), path($acceptedPath)',
    );
    return;
  }

  Log.info('Moving node($node, ${node.path}) to path($newPath)');

  final transaction = editorState.transaction;
  transaction.insertNode(newPath, node.copyWith());
  transaction.deleteNode(node);
  await editorState.apply(transaction);
}

(VerticalPosition, HorizontalPosition, Rect)? getDragAreaPosition(
  BuildContext context,
  Node dragTargetNode,
  Offset dragOffset,
) {
  final selectable = dragTargetNode.selectable;
  final renderBox = selectable?.context.findRenderObject() as RenderBox?;
  if (selectable == null || renderBox == null) {
    return null;
  }

  // disable the table cell block
  if (dragTargetNode.parent?.type == TableCellBlockKeys.type) {
    return null;
  }

  final globalBlockOffset = renderBox.localToGlobal(Offset.zero);
  final globalBlockRect = globalBlockOffset & renderBox.size;

  // Check if the dragOffset is within the globalBlockRect
  final isInside = globalBlockRect.contains(dragOffset);

  if (!isInside) {
    Log.info(
      'the drag offset is not inside the block, dragOffset($dragOffset), globalBlockRect($globalBlockRect)',
    );
    return null;
  }

  // Determine the relative position
  HorizontalPosition horizontalPosition = HorizontalPosition.left;
  VerticalPosition verticalPosition;

  // Horizontal position
  if (dragOffset.dx < globalBlockRect.left + 88) {
    horizontalPosition = HorizontalPosition.left;
  } else if (indentableBlockTypes.contains(dragTargetNode.type)) {
    // For indentable blocks, it means the block can contain a child block.
    // ignore the middle here, it's not used in this example
    horizontalPosition = HorizontalPosition.right;
  }

  // Vertical position
  if (dragOffset.dy < globalBlockRect.top + globalBlockRect.height / 2) {
    verticalPosition = VerticalPosition.top;
  } else {
    verticalPosition = VerticalPosition.bottom;
  }

  return (verticalPosition, horizontalPosition, globalBlockRect);
}

bool shouldIgnoreDragTarget({
  required EditorState editorState,
  required Node dragNode,
  required Path? targetPath,
}) {
  if (targetPath == null) {
    return true;
  }

  if (dragNode.path.equals(targetPath)) {
    return true;
  }

  if (dragNode.path.isAncestorOf(targetPath)) {
    return true;
  }

  final targetNode = editorState.getNodeAtPath(targetPath);
  if (targetNode == null) {
    return true;
  }

  if (targetNode.isInTable) {
    return true;
  }

  return false;
}
