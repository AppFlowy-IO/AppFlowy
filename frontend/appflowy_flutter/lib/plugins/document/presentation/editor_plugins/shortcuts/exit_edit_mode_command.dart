import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// End key event.
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customExitEditingCommand = CommandShortcutEvent(
  key: 'exit the editing mode',
  getDescription: () => AppFlowyEditorL10n.current.cmdExitEditing,
  command: 'escape',
  handler: _exitEditingCommandHandler,
);

CommandShortcutEventHandler _exitEditingCommandHandler = (editorState) {
  if (editorState.selection == null) {
    return KeyEventResult.ignored;
  }
  editorState.selection = null;
  editorState.service.keyboardService?.closeKeyboard();
  return KeyEventResult.handled;
};
