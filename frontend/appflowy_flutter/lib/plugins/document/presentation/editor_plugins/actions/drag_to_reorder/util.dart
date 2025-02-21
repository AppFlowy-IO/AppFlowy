import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum HorizontalPosition { left, center, right }

enum VerticalPosition { top, middle, bottom }

List<String> nodeTypesThatCanContainChildNode = [
  ParagraphBlockKeys.type,
  BulletedListBlockKeys.type,
  NumberedListBlockKeys.type,
  QuoteBlockKeys.type,
  TodoListBlockKeys.type,
  ToggleListBlockKeys.type,
];

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

  // if the horizontal position is right, creating a column block to contain the target node and the drag node
  if (horizontalPosition == HorizontalPosition.right) {
    final columnsNode = simpleColumnsNode(
      children: [
        simpleColumnNode(children: [targetNode.deepCopy()]),
        simpleColumnNode(children: [node.deepCopy()]),
      ],
    );

    final transaction = editorState.transaction;
    transaction.insertNode(newPath, columnsNode);
    transaction.deleteNode(targetNode);
    transaction.deleteNode(node);
    await editorState.apply(transaction);
    return;
  }

  // Determine the new path based on drop position
  // For VerticalPosition.top, we keep the target node's path
  if (verticalPosition == VerticalPosition.bottom) {
    if (horizontalPosition == HorizontalPosition.left) {
      newPath = newPath.next;
    } else if (horizontalPosition == HorizontalPosition.center &&
        nodeTypesThatCanContainChildNode.contains(targetNode.type)) {
      // check if the target node can contain a child node
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
  transaction.insertNode(newPath, node.deepCopy());
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
  } else if (dragTargetNode.level == 1 &&
      dragOffset.dx > globalBlockRect.right / 3.0 * 2.0) {
    horizontalPosition = HorizontalPosition.right;
  } else if (nodeTypesThatCanContainChildNode.contains(dragTargetNode.type)) {
    horizontalPosition = HorizontalPosition.center;
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
  if (targetNode != null &&
      targetNode.isInTable &&
      targetNode.type != SimpleTableBlockKeys.type) {
    return true;
  }

  return false;
}
