import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';

/// Arrow-up inside a multi-line code block moves to the previous line.
///
/// Geometry-based [Position.moveVertical] includes the language-picker
/// header, so arrow-up jumps to the previous block. This command is
/// registered before [arrowUpToTitle] and the standard arrow-up handler.
final CommandShortcutEvent arrowUpInCodeBlock = CommandShortcutEvent(
  key: 'move the cursor up in code block',
  command: 'arrow up',
  getDescription: () => 'move the cursor up in code block',
  handler: _arrowUpInCodeBlockHandler,
);

KeyEventResult _arrowUpInCodeBlockHandler(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  final text = delta.toPlainText();
  final offset = selection.end.offset.clamp(0, text.length);
  if (offset <= 0) {
    return KeyEventResult.ignored;
  }

  final currentLineStart = text.lastIndexOf('\n', offset - 1);
  // First line of the block: let the default handler move to the previous node.
  if (currentLineStart < 0) {
    return KeyEventResult.ignored;
  }

  final column = offset - (currentLineStart + 1);
  final previousLineStart = currentLineStart == 0
      ? 0
      : text.lastIndexOf('\n', currentLineStart - 1) + 1;
  final previousLineLength = currentLineStart - previousLineStart;
  final newOffset = previousLineStart + column.clamp(0, previousLineLength);

  editorState.selection = Selection.collapsed(
    Position(path: node.path, offset: newOffset),
  );

  return KeyEventResult.handled;
}
