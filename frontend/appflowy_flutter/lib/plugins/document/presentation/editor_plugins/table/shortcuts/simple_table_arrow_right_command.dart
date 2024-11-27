import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shortcuts/table_command_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final CommandShortcutEvent arrowRightInTableCell = CommandShortcutEvent(
  key: 'Press arrow right in table cell',
  getDescription: () => AppFlowyEditorL10n
      .current.cmdTableMoveToRightCellIfItsAtTheEndOfCurrentCell,
  command: 'arrow right',
  handler: (editorState) => editorState.moveToNextCell(
    editorState,
    (result) {
      // only handle the case when the selection is at the end of the cell
      final node = result.$4;
      final length = node?.delta?.length ?? 0;
      final selection = result.$2;
      return selection?.end.offset == length;
    },
  ),
);
