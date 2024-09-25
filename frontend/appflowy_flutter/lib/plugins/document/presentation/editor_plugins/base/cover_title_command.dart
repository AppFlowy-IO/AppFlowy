import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final coverTitleFocusNode = editorState.document.root.context
      ?.read<SharedEditorContext>()
      .coverTitleFocusNode;
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
  coverTitleFocusNode.requestFocus();

  return KeyEventResult.handled;
}

/// Press the arrow left at the first position of first line to go to the title
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent arrowLeftToTitle = CommandShortcutEvent(
  key: 'arrow left to title',
  command: 'arrow left',
  getDescription: () => 'arrow left to title',
  // share the same handler with backspaceToTitle
  handler: (editorState) => _backspaceToTitle(
    editorState: editorState,
  ),
);

/// Press the arrow up at the first line to go to the title
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent arrowUpToTitle = CommandShortcutEvent(
  key: 'arrow up to title',
  command: 'arrow up',
  getDescription: () => 'arrow up to title',
  handler: (editorState) => _arrowUpToTitle(
    editorState: editorState,
  ),
);

KeyEventResult _arrowUpToTitle({
  required EditorState editorState,
}) {
  final coverTitleFocusNode = editorState.document.root.context
      ?.read<SharedEditorContext>()
      .coverTitleFocusNode;
  if (coverTitleFocusNode == null) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.selection;
  // only active when the arrow up is at the first line
  if (selection == null ||
      !selection.isCollapsed ||
      !selection.start.path.equals([0])) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null) {
    return KeyEventResult.ignored;
  }

  editorState.selection = null;
  coverTitleFocusNode.requestFocus();

  return KeyEventResult.handled;
}
