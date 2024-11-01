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
    newPath = horizontalPosition == HorizontalPosition.left
        ? newPath.next // Insert after target node
        : newPath.child(0); // Insert as first child of target node
  }

  // Check if the drop should be ignored
  if (shouldIgnoreDragTarget(node, newPath)) {
    Log.info(
      'Drop ignored: node($node, ${node.path}), path($acceptedPath)',
    );
    return;
  }

  Log.info('Moving node($node, ${node.path}) to path($newPath)');

  final newPathNode = editorState.getNodeAtPath(newPath);
  if (newPathNode == null) {
    // if the new path is not a valid path, it means the node is not in the editor.
    // we should perform insertion before deletion.
    final transaction = editorState.transaction;
    transaction.insertNode(newPath, node.copyWith());
    transaction.deleteNode(node);
    await editorState.apply(transaction);
  } else {
    // Perform the node move operation
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    transaction.insertNode(newPath, node.copyWith());
    await editorState.apply(transaction);
  }
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

bool shouldIgnoreDragTarget(Node dragNode, Path? targetPath) {
  if (targetPath == null) {
    return true;
  }

  if (dragNode.path.equals(targetPath)) {
    return true;
  }

  if (dragNode.path.isAncestorOf(targetPath)) {
    return true;
  }

  return false;
}
