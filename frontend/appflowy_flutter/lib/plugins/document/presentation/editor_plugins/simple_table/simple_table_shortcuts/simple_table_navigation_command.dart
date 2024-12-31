import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent tableNavigationArrowDownCommand =
    CommandShortcutEvent(
  key: 'table navigation',
  getDescription: () => 'table navigation',
  command: 'arrow down',
  handler: _tableNavigationArrowDownHandler,
);

KeyEventResult _tableNavigationArrowDownHandler(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  final nextNode = editorState.getNodeAtPath(selection.start.path.next);
  if (nextNode == null) {
    return KeyEventResult.ignored;
  }

  if (nextNode.type == SimpleTableBlockKeys.type) {
    final firstCell = nextNode.getTableCellNode(rowIndex: 0, columnIndex: 0);
    if (firstCell != null) {
      final firstFocusableChild = firstCell.getFirstFocusableChild();
      if (firstFocusableChild != null) {
        editorState.updateSelectionWithReason(
          Selection.collapsed(
            Position(path: firstFocusableChild.path),
          ),
        );
        return KeyEventResult.handled;
      }
    }
  }

  return KeyEventResult.ignored;
}
