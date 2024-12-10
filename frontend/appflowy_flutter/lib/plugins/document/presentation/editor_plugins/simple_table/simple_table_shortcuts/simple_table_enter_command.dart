import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_command_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent enterInTableCell = CommandShortcutEvent(
  key: 'Press enter in table cell',
  getDescription: () => 'Press the enter key in table cell',
  command: 'enter',
  handler: _enterInTableCellHandler,
);

KeyEventResult _enterInTableCellHandler(EditorState editorState) {
  final (isInTableCell, selection, tableCellNode, node) =
      editorState.isCurrentSelectionInTableCell();
  if (!isInTableCell ||
      selection == null ||
      tableCellNode == null ||
      node == null) {
    return KeyEventResult.ignored;
  }

  // forward the enter command to the insertNewLine character command to support multi-line text in table cell
  return KeyEventResult.skipRemainingHandlers;
}
