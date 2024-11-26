import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shortcuts/table_command_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent backspaceInTableCell = CommandShortcutEvent(
  key: 'Press backspace in table cell',
  getDescription: () => 'Ignore the backspace key in table cell',
  command: 'backspace',
  handler: _backspaceInTableCellHandler,
);

KeyEventResult _backspaceInTableCellHandler(EditorState editorState) {
  final (isInTableCell, selection, tableCellNode, node) =
      editorState.isCurrentSelectionInTableCell();
  if (!isInTableCell ||
      selection == null ||
      tableCellNode == null ||
      node == null) {
    return KeyEventResult.ignored;
  }

  final onlyContainsOneChild = tableCellNode.children.length == 1;
  final isParagraphNode =
      tableCellNode.children.first.type == ParagraphBlockKeys.type;
  if (onlyContainsOneChild &&
      selection.isCollapsed &&
      selection.end.offset == 0 &&
      isParagraphNode) {
    return KeyEventResult.skipRemainingHandlers;
  }

  return KeyEventResult.ignored;
}
