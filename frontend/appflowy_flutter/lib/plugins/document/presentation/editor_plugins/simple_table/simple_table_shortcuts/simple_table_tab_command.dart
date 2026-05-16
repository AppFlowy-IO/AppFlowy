import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_command_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_operations.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final CommandShortcutEvent tabInTableCell = CommandShortcutEvent(
  key: 'Press tab in table cell',
  getDescription: () => 'Move the selection to the next cell',
  command: 'tab',
  handler: (editorState) => editorState.moveToNextCell(
    editorState,
    (result) {
      final tableCellNode = result.$3;
      if (tableCellNode?.isLastCellInTable ?? false) {
        return false;
      }
      return true;
    },
  ),
);

final CommandShortcutEvent shiftTabInTableCell = CommandShortcutEvent(
  key: 'Press shift + tab in table cell',
  getDescription: () => 'Move the selection to the previous cell',
  command: 'shift+tab',
  handler: (editorState) => editorState.moveToPreviousCell(
    editorState,
    (result) {
      final tableCellNode = result.$3;
      if (tableCellNode?.isFirstCellInTable ?? false) {
        return false;
      }
      return true;
    },
  ),
);
