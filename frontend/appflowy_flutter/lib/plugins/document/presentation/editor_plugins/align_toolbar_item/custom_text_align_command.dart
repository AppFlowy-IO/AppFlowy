import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final List<CommandShortcutEvent> customTextAlignCommands = [
  customTextLeftAlignCommand,
  customTextCenterAlignCommand,
  customTextRighttAlignCommand,
];

/// Windows / Linux : ctrl + shift + l
/// Mac Os          : ctrl + shift + l
/// Allows the user to align text to the left
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextLeftAlignCommand = CommandShortcutEvent(
  key: 'Align text to the left',
  command: 'ctrl+shift+l',
  macOSCommand: 'ctrl+shift+l',
  handler: _textLeftAlignCommandHandler,
);

/// Windows / Linux : ctrl + shift + e
/// Mac Os          : ctrl + shift + e
/// Allows the user to align text to the center
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextCenterAlignCommand = CommandShortcutEvent(
  key: 'Align text to the center',
  command: 'ctrl+shift+e',
  macOSCommand: 'ctrl+shift+e',
  handler: _textCenterAlignCommandHandler,
);

/// Windows / Linux : ctrl + shift + r
/// Mac Os          : ctrl + shift + r
/// Allows the user to align text to the right
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextRighttAlignCommand = CommandShortcutEvent(
  key: 'Align text to the right',
  command: 'ctrl+shift+r',
  macOSCommand: 'ctrl+shift+r',
  handler: _textRightAlignCommandHandler,
);

CommandShortcutEventHandler _textLeftAlignCommandHandler = (editorState) {
  if (editorState.selection == null) {
    return KeyEventResult.ignored;
  }

  // because the event handler is not async, so we need to use wrap the async function here
  () async {
    await _textAlignHandler(editorState, 'left');
  }();

  return KeyEventResult.handled;
};

CommandShortcutEventHandler _textCenterAlignCommandHandler = (editorState) {
  if (editorState.selection == null) {
    return KeyEventResult.ignored;
  }

  // because the event handler is not async, so we need to use wrap the async function here
  () async {
    await _textAlignHandler(editorState, 'center');
  }();

  return KeyEventResult.handled;
};

CommandShortcutEventHandler _textRightAlignCommandHandler = (editorState) {
  if (editorState.selection == null) {
    return KeyEventResult.ignored;
  }

  // because the event handler is not async, so we need to use wrap the async function here
  () async {
    await _textAlignHandler(editorState, 'right');
  }();

  return KeyEventResult.handled;
};

Future<void> _textAlignHandler(EditorState editorState, String align) async {
  await editorState.updateNode(
    editorState.selection!,
    (node) => node.copyWith(
      attributes: {
        ...node.attributes,
        blockComponentAlign: align,
      },
    ),
  );
}
