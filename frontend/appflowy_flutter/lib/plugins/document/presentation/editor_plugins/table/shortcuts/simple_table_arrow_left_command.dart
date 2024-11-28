import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shortcuts/table_command_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final CommandShortcutEvent arrowLeftInTableCell = CommandShortcutEvent(
  key: 'Press arrow left in table cell',
  getDescription: () => AppFlowyEditorL10n
      .current.cmdTableMoveToRightCellIfItsAtTheEndOfCurrentCell,
  command: 'arrow left',
  handler: (editorState) => editorState.moveToPreviousCell(
    editorState,
    (result) {
      // only handle the case when the selection is at the beginning of the cell
      if (0 != result.$2?.end.offset) {
        return false;
      }
      return true;
    },
  ),
);
