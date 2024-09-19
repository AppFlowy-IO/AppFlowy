import 'package:appflowy/plugins/document/presentation/editor_plugins/header/cover_title.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Press the backspace at the first position of first line to go to the title
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent backspaceToTitle = CommandShortcutEvent(
  key: 'backspace to title',
  command: 'backspace',
  getDescription: () => 'backspace to title',
  handler: (editorState) => _backspaceToTitle(
    editorState: editorState,
  ),
);

KeyEventResult _backspaceToTitle({
  required EditorState editorState,
}) {
  if (coverTitleFocusNode == null) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.selection;
  // only active when the backspace is at the first position of first line
  if (selection == null ||
      !selection.isCollapsed ||
      !selection.start.path.equals([0]) ||
      selection.start.offset != 0) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.type != ParagraphBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  editorState.selection = null;
  coverTitleFocusNode?.requestFocus();

  return KeyEventResult.handled;
}
