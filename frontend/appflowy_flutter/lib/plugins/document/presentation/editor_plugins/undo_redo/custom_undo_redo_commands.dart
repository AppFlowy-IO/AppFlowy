import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';

/// Undo
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customUndoCommand = CommandShortcutEvent(
  key: 'undo',
  getDescription: () => AppFlowyEditorL10n.current.cmdUndo,
  command: 'ctrl+z',
  macOSCommand: 'cmd+z',
  handler: (editorState) {
    // if the selection is null, it means the keyboard service is disabled
    if (editorState.selection == null) {
      return KeyEventResult.ignored;
    }
    EditorNotification.undo().post();
    return KeyEventResult.handled;
  },
);

/// Redo
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customRedoCommand = CommandShortcutEvent(
  key: 'redo',
  getDescription: () => AppFlowyEditorL10n.current.cmdRedo,
  command: 'ctrl+y,ctrl+shift+z',
  macOSCommand: 'cmd+shift+z',
  handler: (editorState) {
    if (editorState.selection == null) {
      return KeyEventResult.ignored;
    }
    EditorNotification.redo().post();
    return KeyEventResult.handled;
  },
);
