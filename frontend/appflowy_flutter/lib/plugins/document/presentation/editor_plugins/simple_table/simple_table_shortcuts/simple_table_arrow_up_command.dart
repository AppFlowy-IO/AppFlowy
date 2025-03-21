import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_command_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_operations.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent arrowUpInTableCell = CommandShortcutEvent(
  key: 'Press arrow up in table cell',
  getDescription: () =>
      AppFlowyEditorL10n.current.cmdTableMoveToUpCellAtSameOffset,
  command: 'arrow up',
  handler: _arrowUpInTableCellHandler,
);

/// Move the selection to the previous cell in the same column.
///
/// Only handle the case when the selection is in the first line of the cell.
KeyEventResult _arrowUpInTableCellHandler(EditorState editorState) {
  final (isInTableCell, selection, tableCellNode, node) =
      editorState.isCurrentSelectionInTableCell();
  if (!isInTableCell ||
      selection == null ||
      tableCellNode == null ||
      node == null) {
    return KeyEventResult.ignored;
  }

  final isInFirstLine = node.path.last == 0;
  if (!isInFirstLine) {
    return KeyEventResult.ignored;
  }

  Selection? newSelection = editorState.selection;
  final rowIndex = tableCellNode.rowIndex;
  if (rowIndex == 0) {
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
  } else {
    // focus on previous cell in the same column
    final previousCell = tableCellNode.getPreviousCellInSameColumn();
    if (previousCell != null) {
      final offset = selection.end.offset;
      // get the last children of the previous cell
      final lastChild = previousCell.children.lastWhereOrNull(
        (c) => c.delta != null,
      );
      if (lastChild != null) {
        final length = lastChild.delta?.length ?? 0;
        newSelection = Selection.collapsed(
          Position(
            path: lastChild.path,
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
