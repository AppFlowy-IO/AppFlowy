import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shortcuts/table_command_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_operations.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent arrowDownInTableCell = CommandShortcutEvent(
  key: 'Press arrow down in table cell',
  getDescription: () =>
      AppFlowyEditorL10n.current.cmdTableMoveToDownCellAtSameOffset,
  command: 'arrow down',
  handler: _arrowDownInTableCellHandler,
);

/// Move the selection to the next cell in the same column.
///
/// Only handle the case when the selection is in the first line of the cell.
KeyEventResult _arrowDownInTableCellHandler(EditorState editorState) {
  final (isInTableCell, selection, tableCellNode, node) =
      editorState.isCurrentSelectionInTableCell();
  if (!isInTableCell ||
      selection == null ||
      tableCellNode == null ||
      node == null) {
    return KeyEventResult.ignored;
  }

  final isInLastLine = node.path.last + 1 == node.parent?.children.length;
  if (!isInLastLine) {
    return KeyEventResult.ignored;
  }

  Selection? newSelection = editorState.selection;
  final rowIndex = tableCellNode.rowIndex;
  final parentTableNode = tableCellNode.parentTableNode;
  if (parentTableNode == null) {
    return KeyEventResult.ignored;
  }

  if (rowIndex == parentTableNode.rowLength - 1) {
    // focus on the next block
    final nextNode = tableCellNode.next;
    if (nextNode != null) {
      final nextFocusableSibling = parentTableNode.getNextFocusableSibling();
      if (nextFocusableSibling != null) {
        final length = nextFocusableSibling.delta?.length ?? 0;
        newSelection = Selection.collapsed(
          Position(
            path: nextFocusableSibling.path,
            offset: length,
          ),
        );
      }
    }
  } else {
    // focus on next cell in the same column
    final nextCell = tableCellNode.getNextCellInSameColumn();
    if (nextCell != null) {
      final offset = selection.end.offset;
      // get the first children of the next cell
      final firstChild = nextCell.children.firstWhereOrNull(
        (c) => c.delta != null,
      );
      if (firstChild != null) {
        final length = firstChild.delta?.length ?? 0;
        newSelection = Selection.collapsed(
          Position(
            path: firstChild.path,
            offset: offset.clamp(0, length),
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
