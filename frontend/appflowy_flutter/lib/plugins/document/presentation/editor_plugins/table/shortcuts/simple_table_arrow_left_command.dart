import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shortcuts/table_command_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_operations.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent arrowLeftInTableCell = CommandShortcutEvent(
  key: 'Press arrow left in table cell',
  getDescription: () => AppFlowyEditorL10n
      .current.cmdTableMoveToRightCellIfItsAtTheEndOfCurrentCell,
  command: 'arrow left',
  handler: _arrowLeftInTableCellHandler,
);

/// Move the selection to the previous cell in the same column.
KeyEventResult _arrowLeftInTableCellHandler(EditorState editorState) {
  final (isInTableCell, selection, tableCellNode, node) =
      editorState.isCurrentSelectionInTableCell();
  if (!isInTableCell ||
      selection == null ||
      tableCellNode == null ||
      node == null) {
    return KeyEventResult.ignored;
  }

  // only handle the case when the selection is at the beginning of the cell
  if (0 != selection.end.offset) {
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
