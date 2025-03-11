import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    hide QuoteBlockKeys, quoteNode;
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

  if (shouldIgnoreDragTarget(
    editorState: editorState,
    dragNode: node,
    targetPath: acceptedPath,
  )) {
    Log.info('Drop ignored: node($node, ${node.path}), path($acceptedPath)');
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
    // 1. if the targetNode is a column block, it means we should create a column block to contain the node and insert the column node to the target node's parent
    // 2. if the targetNode is not a column block, it means we should create a columns block to contain the target node and the drag node
    final transaction = editorState.transaction;
    final targetNodeParent = targetNode.columnsParent;

    if (targetNodeParent != null) {
      final length = targetNodeParent.children.length;
      final ratios = targetNodeParent.children
          .map(
            (e) =>
                e.attributes[SimpleColumnBlockKeys.ratio]?.toDouble() ??
                1.0 / length,
          )
          .map((e) => e * length / (length + 1))
          .toList();

      final columnNode = simpleColumnNode(
        children: [node.deepCopy()],
        ratio: 1.0 / (length + 1),
      );
      for (final (index, column) in targetNodeParent.children.indexed) {
        transaction.updateNode(column, {
          ...column.attributes,
          SimpleColumnBlockKeys.ratio: ratios[index],
        });
      }

      transaction.insertNode(targetNode.path.next, columnNode);
      transaction.deleteNode(node);
    } else {
      final columnsNode = simpleColumnsNode(
        children: [
          simpleColumnNode(children: [targetNode.deepCopy()], ratio: 0.5),
          simpleColumnNode(children: [node.deepCopy()], ratio: 0.5),
        ],
      );

      transaction.insertNode(newPath, columnsNode);
      transaction.deleteNode(targetNode);
      transaction.deleteNode(node);
    }

    if (transaction.operations.isNotEmpty) {
      await editorState.apply(transaction);
    }
    return;
  } else if (horizontalPosition == HorizontalPosition.left &&
      verticalPosition == VerticalPosition.middle) {
    // 1. if the target node is a column block, we should create a column block to contain the node and insert the column node to the target node's parent
    // 2. if the target node is not a column block, we should create a columns block to contain the target node and the drag node
    final transaction = editorState.transaction;
    final targetNodeParent = targetNode.columnsParent;
    if (targetNodeParent != null) {
      // find the previous sibling node of the target node
      final length = targetNodeParent.children.length;
      final ratios = targetNodeParent.children
          .map(
            (e) =>
                e.attributes[SimpleColumnBlockKeys.ratio]?.toDouble() ??
                1.0 / length,
          )
          .map((e) => e * length / (length + 1))
          .toList();
      final columnNode = simpleColumnNode(
        children: [node.deepCopy()],
        ratio: 1.0 / (length + 1),
      );

      for (final (index, column) in targetNodeParent.children.indexed) {
        transaction.updateNode(column, {
          ...column.attributes,
          SimpleColumnBlockKeys.ratio: ratios[index],
        });
      }

      transaction.insertNode(targetNode.path.previous, columnNode);
      transaction.deleteNode(node);
    } else {
      final columnsNode = simpleColumnsNode(
        children: [
          simpleColumnNode(children: [node.deepCopy()], ratio: 0.5),
          simpleColumnNode(children: [targetNode.deepCopy()], ratio: 0.5),
        ],
      );

      transaction.insertNode(newPath, columnsNode);
      transaction.deleteNode(targetNode);
      transaction.deleteNode(node);
    }

    if (transaction.operations.isNotEmpty) {
      await editorState.apply(transaction);
    }
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
  debugPrint('getDragAreaPosition - dragTargetNode: ${dragTargetNode.type}');
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

  // | ----------------------------- block ----------------------------- |
  // | 1. -- 88px --| 2. ---------------------------- | 3. ---- 1/5 ---- |
  // 1. drag the node under the block as a sibling node
  // 2. drag the node inside the block as a child node
  // 3. create a column block to contain the node and the drag node

  // Horizontal position, please refer to the diagram above
  // 88px is a hardcoded value, it can be changed based on the project's design
  if (dragOffset.dx < globalBlockRect.left + 88) {
    horizontalPosition = HorizontalPosition.left;
  } else if (dragOffset.dx > globalBlockRect.right * 4.0 / 5.0) {
    horizontalPosition = HorizontalPosition.right;
  } else if (nodeTypesThatCanContainChildNode.contains(dragTargetNode.type)) {
    horizontalPosition = HorizontalPosition.center;
  }

  // | ----------------------------------------------------------------- | <- if the drag position is in this area, the vertical position is top
  // | ----------------------------- block ----------------------------- | <- if the drag position is in this area, the vertical position is middle
  // | ----------------------------------------------------------------- | <- if the drag position is in this area, the vertical position is bottom

  // Vertical position
  final heightThird = globalBlockRect.height / 3;
  if (dragOffset.dy < globalBlockRect.top + heightThird) {
    verticalPosition = VerticalPosition.top;
  } else if (dragOffset.dy < globalBlockRect.top + heightThird * 2) {
    verticalPosition = VerticalPosition.middle;
  } else {
    verticalPosition = VerticalPosition.bottom;
  }

  debugPrint(
    'verticalPosition: $verticalPosition, horizontalPosition: $horizontalPosition',
  );

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
