import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_operations.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

typedef IsInTableCellResult = (
  bool isInTableCell,
  Selection? selection,
  Node? tableCellNode,
  Node? node,
);

extension TableCommandExtension on EditorState {
  /// Return a tuple, the first element is a boolean indicating whether the current selection is in a table cell,
  /// the second element is the node that is the parent of the table cell if the current selection is in a table cell,
  /// otherwise it is null.
  /// The third element is the node that is the current selection.
  IsInTableCellResult isCurrentSelectionInTableCell() {
    final selection = this.selection;
    if (selection == null) {
      return (false, null, null, null);
    }

    if (selection.isCollapsed) {
      // if the selection is collapsed, check if the node is in a table cell
      final node = document.nodeAtPath(selection.end.path);
      final tableCellParent = node?.findParent(
        (node) => node.type == SimpleTableCellBlockKeys.type,
      );
      final isInTableCell = tableCellParent != null;
      return (isInTableCell, selection, tableCellParent, node);
    } else {
      // if the selection is not collapsed, check if the start and end nodes are in a table cell
      final startNode = document.nodeAtPath(selection.start.path);
      final endNode = document.nodeAtPath(selection.end.path);
      final startNodeInTableCell = startNode?.findParent(
        (node) => node.type == SimpleTableCellBlockKeys.type,
      );
      final endNodeInTableCell = endNode?.findParent(
        (node) => node.type == SimpleTableCellBlockKeys.type,
      );
      final isInSameTableCell = startNodeInTableCell != null &&
          endNodeInTableCell != null &&
          startNodeInTableCell.path.equals(endNodeInTableCell.path);
      return (isInSameTableCell, selection, startNodeInTableCell, endNode);
    }
  }

  /// Move the selection to the previous cell
  KeyEventResult moveToPreviousCell(
    EditorState editorState,
    bool Function(IsInTableCellResult result) shouldHandle,
  ) {
    final (isInTableCell, selection, tableCellNode, node) =
        editorState.isCurrentSelectionInTableCell();
    if (!isInTableCell ||
        selection == null ||
        tableCellNode == null ||
        node == null) {
      return KeyEventResult.ignored;
    }

    if (!shouldHandle((isInTableCell, selection, tableCellNode, node))) {
      return KeyEventResult.ignored;
    }

    Selection? newSelection;

    final previousCell = tableCellNode.getPreviousCellInSameRow();
    if (previousCell != null && !previousCell.path.equals(tableCellNode.path)) {
      // get the last children of the previous cell
      final lastChild = previousCell.children.lastWhereOrNull(
        (c) => c.delta != null,
      );
      if (lastChild != null) {
        newSelection = Selection.collapsed(
          Position(
            path: lastChild.path,
            offset: lastChild.delta?.length ?? 0,
          ),
        );
      }
    } else {
      // focus on the previous block
      final previousNode = tableCellNode.parentTableNode;
      if (previousNode != null) {
        final previousFocusableSibling =
            previousNode.getPreviousFocusableSibling();
        if (previousFocusableSibling != null) {
          final length = previousFocusableSibling.delta?.length ?? 0;
          newSelection = Selection.collapsed(
            Position(
              path: previousFocusableSibling.path,
              offset: length,
            ),
          );
        }
      }
    }

    if (newSelection != null) {
      editorState.updateSelectionWithReason(newSelection);
    }

    return KeyEventResult.handled;
  }

  /// Move the selection to the next cell
  KeyEventResult moveToNextCell(
    EditorState editorState,
    bool Function(IsInTableCellResult result) shouldHandle,
  ) {
    final (isInTableCell, selection, tableCellNode, node) =
        editorState.isCurrentSelectionInTableCell();
    if (!isInTableCell ||
        selection == null ||
        tableCellNode == null ||
        node == null) {
      return KeyEventResult.ignored;
    }

    if (!shouldHandle((isInTableCell, selection, tableCellNode, node))) {
      return KeyEventResult.ignored;
    }

    Selection? newSelection;

    final nextCell = tableCellNode.getNextCellInSameRow();
    if (nextCell != null && !nextCell.path.equals(tableCellNode.path)) {
      // get the first children of the next cell
      final firstChild = nextCell.children.firstWhereOrNull(
        (c) => c.delta != null,
      );
      if (firstChild != null) {
        newSelection = Selection.collapsed(
          Position(
            path: firstChild.path,
          ),
        );
      }
    } else {
      // focus on the previous block
      final nextNode = tableCellNode.parentTableNode;
      if (nextNode != null) {
        final nextFocusableSibling = nextNode.getNextFocusableSibling();
        nextNode.getNextFocusableSibling();
        if (nextFocusableSibling != null) {
          newSelection = Selection.collapsed(
            Position(
              path: nextFocusableSibling.path,
            ),
          );
        }
      }
    }

    if (newSelection != null) {
      editorState.updateSelectionWithReason(newSelection);
    }

    return KeyEventResult.handled;
  }
}
