import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final context = editorState.document.root.context;
    if (context == null) {
      return KeyEventResult.ignored;
    }
    final editorContext = context.read<SharedEditorContext>();
    if (editorContext.coverTitleFocusNode.hasFocus) {
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
    final context = editorState.document.root.context;
    if (context == null) {
      return KeyEventResult.ignored;
    }
    final editorContext = context.read<SharedEditorContext>();
    if (editorContext.coverTitleFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    EditorNotification.redo().post();
    return KeyEventResult.handled;
  },
);
