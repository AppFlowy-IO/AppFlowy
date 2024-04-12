import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

final List<CharacterShortcutEvent> codeBlockCharacterEvents = [
  enterInCodeBlock,
  ...ignoreKeysInCodeBlock,
  insertCodeBlock,
];

final List<CommandShortcutEvent> codeBlockCommands = [
  insertNewParagraphNextToCodeBlockCommand,
  pasteInCodeblock,
  selectAllInCodeBlockCommand,
  tabToInsertSpacesInCodeBlockCommand,
  tabToDeleteSpacesInCodeBlockCommand,
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
    [' ', '/', '_', '*', '~', '-']
        .map(
          (e) => CharacterShortcutEvent(
            key: 'ignore key press in code block',
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
  getDescription:
      LocaleKeys.settings_shortcuts_commands_codeBlockNewParagraph.tr,
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
  getDescription:
      LocaleKeys.settings_shortcuts_commands_codeBlockAddTwoSpaces.tr,
  handler: (editorState) => _indentationInCodeBlockCommandHandler(
    editorState,
    true,
  ),
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
  getDescription:
      LocaleKeys.settings_shortcuts_commands_codeBlockDeleteTwoSpaces.tr,
  handler: (editorState) => _indentationInCodeBlockCommandHandler(
    editorState,
    false,
  ),
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
  getDescription: LocaleKeys.settings_shortcuts_commands_codeBlockSelectAll.tr,
  handler: _selectAllInCodeBlockCommandHandler,
);

/// ctrl + v to paste text in code block.
///
/// - support
///   - desktop
///   - web
final CommandShortcutEvent pasteInCodeblock = CommandShortcutEvent(
  key: 'paste in codeblock',
  command: 'ctrl+v',
  macOSCommand: 'cmd+v',
  getDescription: LocaleKeys.settings_shortcuts_commands_codeBlockPasteText.tr,
  handler: _pasteInCodeBlock,
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

  final lines = node.delta?.toPlainText().split('\n');
  int spaces = 0;
  if (lines?.isNotEmpty == true) {
    int index = 0;
    for (final line in lines!) {
      if (index <= selection.endIndex &&
          selection.endIndex <= index + line.length) {
        final lineSpaces = line.length - line.trimLeft().length;
        spaces = lineSpaces;
        break;
      }
      index += line.length + 1;
    }
  }

  final transaction = editorState.transaction
    ..insertText(
      node,
      selection.end.offset,
      '\n${' ' * spaces}',
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
    ..afterSelection = Selection.collapsed(
      Position(path: selection.end.path.next),
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
};

KeyEventResult _indentationInCodeBlockCommandHandler(
  EditorState editorState,
  bool shouldIndent,
) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  const spaces = '  ';
  final lines = delta.toPlainText().split('\n');
  int index = 0;

  // We store indexes to be indented in a list, because we should
  // indent it in a reverse order to not mess up the offsets.
  final List<int> transactions = [];

  for (final line in lines) {
    if (!shouldIndent && line.startsWith(spaces) || shouldIndent) {
      bool shouldTransform = false;
      if (selection.isCollapsed) {
        shouldTransform = index <= selection.endIndex &&
            selection.endIndex <= index + line.length;
      } else {
        shouldTransform = index + line.length >= selection.startIndex &&
            selection.endIndex >= index;

        if (shouldIndent && line.trim().isEmpty) {
          shouldTransform = false;
        }
      }

      if (shouldTransform) {
        transactions.add(index);
      }
    }

    index += line.length + 1;
  }

  if (transactions.isEmpty) {
    return KeyEventResult.ignored;
  }

  final transaction = editorState.transaction;

  for (final index in transactions.reversed) {
    if (shouldIndent) {
      transaction.insertText(node, index, spaces);
    } else {
      transaction.deleteText(node, index, spaces.length);
    }
  }

  // In case the selection is made backwards, we store the start
  // and end here, we will adjust the order later
  final start = !selection.isBackward ? selection.end : selection.start;
  final end = !selection.isBackward ? selection.start : selection.end;

  final endOffset = shouldIndent
      ? end.offset + (spaces.length * transactions.length)
      : end.offset - (spaces.length * transactions.length);

  final endSelection = end.copyWith(offset: endOffset);

  final startOffset = shouldIndent
      ? start.offset + spaces.length
      : start.offset - spaces.length;

  final startSelection = selection.isCollapsed
      ? endSelection
      : start.copyWith(offset: startOffset);

  transaction.afterSelection = selection.copyWith(
    start: selection.isBackward ? startSelection : endSelection,
    end: selection.isBackward ? endSelection : startSelection,
  );

  editorState.apply(transaction);

  return KeyEventResult.handled;
}

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

CommandShortcutEventHandler _pasteInCodeBlock = (editorState) {
  var selection = editorState.selection;

  if (selection == null) {
    return KeyEventResult.ignored;
  }

  if (editorState.getNodesInSelection(selection).length != 1) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  // delete the selection first.
  if (!selection.isCollapsed) {
    editorState.deleteSelection(selection);
  }

  // fetch selection again.
  selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.skipRemainingHandlers;
  }
  assert(selection.isCollapsed);

  () async {
    final data = await AppFlowyClipboard.getData();
    final text = data.text;
    if (text != null && text.isNotEmpty) {
      final transaction = editorState.transaction
        ..insertText(
          node,
          selection!.end.offset,
          text,
        );

      await editorState.apply(transaction);
    }
  }();

  return KeyEventResult.handled;
};

/// ``` to insert a Code Block
/// - support
///  - desktop
///  - web
///  - mobile
///
final CharacterShortcutEvent insertCodeBlock = CharacterShortcutEvent(
  key: 'insert code block',
  character: '`',
  handler: _insertCodeBlockHandler,
);

CharacterShortcutEventHandler _insertCodeBlockHandler = (editorState) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != ParagraphBlockKeys.type) {
    return false;
  }

  final plainText = delta.toPlainText();
  bool startOfLine = false;
  if (plainText.length == 2) {
    final testString = plainText.substring(
      selection.end.offset - 2,
      selection.end.offset,
    );

    if (testString != '``') {
      return false;
    }

    startOfLine = true;
  } else if (plainText.length > 2) {
    final testString = plainText.substring(
      selection.end.offset - 3,
      selection.end.offset,
    );

    if (testString != ' ``') {
      return false;
    }
  } else {
    return false;
  }

  final transaction = editorState.transaction
    ..replaceText(
      node,
      selection.end.offset - 2,
      2,
      '',
    )
    ..insertNode(
      startOfLine ? node.path : node.path.next,
      codeBlockNode(),
    )
    ..afterSelection = Selection.collapsed(
      Position(path: startOfLine ? node.path : node.path.next),
    );

  if (startOfLine) {
    transaction.deleteNode(node);
  }

  await editorState.apply(transaction);
  return true;
};
