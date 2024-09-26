import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// cut.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CommandShortcutEvent customCutCommand = CommandShortcutEvent(
  key: 'cut the selected content',
  getDescription: () => AppFlowyEditorL10n.current.cmdCutSelection,
  command: 'ctrl+x',
  macOSCommand: 'cmd+x',
  handler: _cutCommandHandler,
);

CommandShortcutEventHandler _cutCommandHandler = (editorState) {
  handleCopyCommand(editorState, isCut: true);
  editorState.deleteSelectionIfNeeded();
  return KeyEventResult.handled;
};
