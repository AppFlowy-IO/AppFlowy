import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_command_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent selectAllInTableCellCommand = CommandShortcutEvent(
  key: 'Select all contents in table cell',
  getDescription: () => 'Select all contents in table cell',
  command: 'ctrl+a',
  macOSCommand: 'cmd+a',
  handler: _selectAllInTableCellHandler,
);

KeyEventResult _selectAllInTableCellHandler(EditorState editorState) {
  final (isInTableCell, selection, tableCellNode, _) =
      editorState.isCurrentSelectionInTableCell();
  if (!isInTableCell || selection == null || tableCellNode == null) {
    return KeyEventResult.ignored;
  }

  final firstFocusableChild = tableCellNode.children.firstWhereOrNull(
    (e) => e.delta != null,
  );
  final lastFocusableChild = tableCellNode.lastChildWhere(
    (e) => e.delta != null,
  );
  if (firstFocusableChild == null || lastFocusableChild == null) {
    return KeyEventResult.ignored;
  }

  final afterSelection = Selection(
    start: Position(path: firstFocusableChild.path),
    end: Position(
      path: lastFocusableChild.path,
      offset: lastFocusableChild.delta?.length ?? 0,
    ),
  );

  if (afterSelection == editorState.selection) {
    // Focus on the cell already
    return KeyEventResult.ignored;
  } else {
    editorState.selection = afterSelection;
    return KeyEventResult.handled;
  }
}
