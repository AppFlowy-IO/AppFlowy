import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final List<CommandShortcutEvent> customTextAlignCommands = [
  customTextLeftAlignCommand,
  customTextCenterAlignCommand,
  customTextRightAlignCommand,
];

/// Windows / Linux : ctrl + shift + l
/// macOs           : ctrl + shift + l
/// Allows the user to align text to the left
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextLeftAlignCommand = CommandShortcutEvent(
  key: 'Align text to the left',
  command: 'ctrl+shift+l',
  handler: (editorState) => _textAlignHandler(editorState, leftAlignmentKey),
);

/// Windows / Linux : ctrl + shift + e
/// macOs           : ctrl + shift + e
/// Allows the user to align text to the center
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextCenterAlignCommand = CommandShortcutEvent(
  key: 'Align text to the center',
  command: 'ctrl+shift+e',
  handler: (editorState) => _textAlignHandler(editorState, centerAlignmentKey),
);

/// Windows / Linux : ctrl + shift + r
/// macOs           : ctrl + shift + r
/// Allows the user to align text to the right
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextRightAlignCommand = CommandShortcutEvent(
  key: 'Align text to the right',
  command: 'ctrl+shift+r',
  handler: (editorState) => _textAlignHandler(editorState, rightAlignmentKey),
);

KeyEventResult _textAlignHandler(EditorState editorState, String align) {
  final Selection? selection = editorState.selection;

  if (selection == null) {
    return KeyEventResult.ignored;
  }

  // because the event handler is not async, so we need to use wrap the async function here
  () async {
    await editorState.updateNode(
      selection,
      (node) => node.copyWith(
        attributes: {
          ...node.attributes,
          blockComponentAlign: align,
        },
      ),
    );
  }();

  return KeyEventResult.handled;
}
