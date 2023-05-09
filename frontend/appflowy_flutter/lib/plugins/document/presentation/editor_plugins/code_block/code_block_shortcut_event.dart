import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// press the enter key in code block to insert a new line in it.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CharacterShortcutEvent enterInCodeBlockCommand = CharacterShortcutEvent(
  key: 'press enter in code block',
  character: '\n',
  handler: _enterInCodeBlockCommandHandler,
);

/// ignore ' ', '/', '_', '*' in code block.
///
/// - support
///   - desktop
///   - web
///
final List<CharacterShortcutEvent> ignoreKeysInCodeBlockCommands =
    [' ', '/', '_', '*']
        .map(
          (e) => CharacterShortcutEvent(
            key: 'press enter in code block',
            character: e,
            handler: _ignoreKeysInCodeBlockCommandHandler,
          ),
        )
        .toList();

/// shift + enter to insert a new node next to the code block.
final CommandShortcutEvent insertNewParagraphNextToCodeBlockCommand =
    CommandShortcutEvent(
  key: 'insert a new paragraph next to the code block',
  command: 'shift+enter',
  handler: _insertNewParagraphNextToCodeBlockCommandHandler,
);

CharacterShortcutEventHandler _enterInCodeBlockCommandHandler =
    (editorState) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.type != CodeBlockKeys.type) {
    return false;
  }
  final transaction = editorState.transaction
    ..insertText(
      node,
      selection.end.offset,
      '\n',
    );
  await editorState.apply(transaction);
  return true;
};

CharacterShortcutEventHandler _ignoreKeysInCodeBlockCommandHandler =
    (editorState) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.type != CodeBlockKeys.type) {
    return false;
  }
  return true;
};

CommandShortcutEventHandler _insertNewParagraphNextToCodeBlockCommandHandler =
    (editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }
  final sliced = delta.slice(selection.startIndex);
  final transaction = editorState.transaction
    ..deleteText(
      node,
      selection.startIndex,
      delta.length - selection.startIndex,
    )
    ..insertNode(
      selection.end.path.next,
      paragraphNode(
        attributes: {
          'delta': sliced.toJson(),
        },
      ),
    )
    ..afterSelection = Selection.collapse(
      selection.end.path.next,
      0,
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
};
