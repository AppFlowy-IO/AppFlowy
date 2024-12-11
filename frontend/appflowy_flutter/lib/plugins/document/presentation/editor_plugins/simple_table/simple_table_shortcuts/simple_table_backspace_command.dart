import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_command_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
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
  final isCodeBlock = tableCellNode.children.first.type == CodeBlockKeys.type;
  if (onlyContainsOneChild &&
      selection.isCollapsed &&
      selection.end.offset == 0) {
    if (isParagraphNode) {
      return KeyEventResult.skipRemainingHandlers;
    } else if (isCodeBlock) {
      // replace the codeblock with a paragraph
      final transaction = editorState.transaction;
      transaction.insertNode(node.path, paragraphNode());
      transaction.deleteNode(node);
      transaction.afterSelection = Selection.collapsed(
        Position(
          path: node.path,
        ),
      );
      editorState.apply(transaction);
      return KeyEventResult.handled;
    }
  }

  return KeyEventResult.ignored;
}
