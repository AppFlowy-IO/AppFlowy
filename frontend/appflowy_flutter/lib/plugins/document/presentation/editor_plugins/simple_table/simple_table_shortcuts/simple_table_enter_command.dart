import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_command_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      node == null ||
      !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  // check if the shift key is pressed, if so, we should return false to let the system handle it.
  final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
  if (isShiftPressed) {
    return KeyEventResult.ignored;
  }

  final delta = node.delta;
  if (!indentableBlockTypes.contains(node.type) || delta == null) {
    return KeyEventResult.ignored;
  }

  if (selection.startIndex == 0 && delta.isEmpty) {
    // clear the style
    if (node.parent?.type != SimpleTableCellBlockKeys.type) {
      if (outdentCommand.execute(editorState) == KeyEventResult.handled) {
        return KeyEventResult.handled;
      }
    }
    if (node.type != CalloutBlockKeys.type) {
      return convertToParagraphCommand.execute(editorState);
    }
  }

  return KeyEventResult.ignored;
}
