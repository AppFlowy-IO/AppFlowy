import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final List<CharacterShortcutEvent> codeBlockCharacterEvents = [
  enterInCodeBlock,
  ...ignoreKeysInCodeBlock,
];

final List<CommandShortcutEvent> codeBlockCommands = [
  insertNewParagraphNextToCodeBlockCommand,
  tabToInsertSpacesInCodeBlockCommand,
  tabToDeleteSpacesInCodeBlockCommand,
  selectAllInCodeBlockCommand,
];

/// press the enter key in code block to insert a new line in it.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CharacterShortcutEvent enterInCodeBlock = CharacterShortcutEvent(
  key: 'press enter in code block',
  character: '\n',
  handler: _enterInCodeBlockCommandHandler,
);

/// ignore ' ', '/', '_', '*' in code block.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final List<CharacterShortcutEvent> ignoreKeysInCodeBlock =
    [' ', '/', '_', '*', '~']
        .map(
          (e) => CharacterShortcutEvent(
            key: 'press enter in code block',
            character: e,
            handler: (editorState) => _ignoreKeysInCodeBlockCommandHandler(
              editorState,
              e,
            ),
          ),
        )
        .toList();

/// shift + enter to insert a new node next to the code block.
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent insertNewParagraphNextToCodeBlockCommand =
    CommandShortcutEvent(
  key: 'insert a new paragraph next to the code block',
  command: 'shift+enter',
  handler: _insertNewParagraphNextToCodeBlockCommandHandler,
);

/// tab to insert two spaces at the line start in code block.
///
/// - support
///   - desktop
///   - web
final CommandShortcutEvent tabToInsertSpacesInCodeBlockCommand =
    CommandShortcutEvent(
  key: 'tab to insert two spaces at the line start in code block',
  command: 'tab',
  handler: _tabToInsertSpacesInCodeBlockCommandHandler,
);

/// shift+tab to delete two spaces at the line start in code block if needed.
///
/// - support
///   - desktop
///   - web
final CommandShortcutEvent tabToDeleteSpacesInCodeBlockCommand =
    CommandShortcutEvent(
  key: 'shift + tab to delete two spaces at the line start in code block',
  command: 'shift+tab',
  handler: _tabToDeleteSpacesInCodeBlockCommandHandler,
);

/// CTRL+A to select all content inside a Code Block, if cursor is inside one.
///
/// - support
///   - desktop
///   - web
final CommandShortcutEvent selectAllInCodeBlockCommand = CommandShortcutEvent(
  key: 'ctrl + a to select all content inside a code block',
  command: 'ctrl+a',
  macOSCommand: 'meta+a',
  handler: _selectAllInCodeBlockCommandHandler,
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

Future<bool> _ignoreKeysInCodeBlockCommandHandler(
  EditorState editorState,
  String key,
) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.type != CodeBlockKeys.type) {
    return false;
  }
  await editorState.insertTextAtCurrentSelection(key);
  return true;
}

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
      // delete the text after the cursor in the code block
      node,
      selection.startIndex,
      delta.length - selection.startIndex,
    )
    ..insertNode(
      // insert a new paragraph node with the sliced delta after the code block
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

CommandShortcutEventHandler _tabToInsertSpacesInCodeBlockCommandHandler =
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
  const spaces = '  ';
  final lines = delta.toPlainText().split('\n');
  var index = 0;
  for (final line in lines) {
    if (index <= selection.endIndex &&
        selection.endIndex <= index + line.length) {
      final transaction = editorState.transaction
        ..insertText(
          node,
          index,
          spaces, // two spaces
        )
        ..afterSelection = Selection.collapse(
          selection.end.path,
          selection.endIndex + spaces.length,
        );
      editorState.apply(transaction);
      break;
    }
    index += line.length + 1;
  }
  return KeyEventResult.handled;
};

CommandShortcutEventHandler _tabToDeleteSpacesInCodeBlockCommandHandler =
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
  const spaces = '  ';
  final lines = delta.toPlainText().split('\n');
  var index = 0;
  for (final line in lines) {
    if (index <= selection.endIndex &&
        selection.endIndex <= index + line.length) {
      if (line.startsWith(spaces)) {
        final transaction = editorState.transaction
          ..deleteText(
            node,
            index,
            spaces.length, // two spaces
          )
          ..afterSelection = Selection.collapse(
            selection.end.path,
            selection.endIndex - spaces.length,
          );
        editorState.apply(transaction);
      }
      break;
    }
    index += line.length + 1;
  }
  return KeyEventResult.handled;
};

CommandShortcutEventHandler _selectAllInCodeBlockCommandHandler =
    (editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isSingle) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  editorState.service.selectionService.updateSelection(
    Selection.single(
      path: node.path,
      startOffset: 0,
      endOffset: delta.length,
    ),
  );

  return KeyEventResult.handled;
};
