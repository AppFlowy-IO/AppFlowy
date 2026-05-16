import 'package:appflowy/plugins/emoji/emoji_actions_command.dart';
import 'package:appflowy/plugins/emoji/emoji_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent emojiShortcutEvent = CommandShortcutEvent(
  key: 'Ctrl + Alt + E to show emoji picker',
  command: 'ctrl+alt+e',
  macOSCommand: 'cmd+alt+e',
  getDescription: () => 'Show an emoji picker',
  handler: _emojiShortcutHandler,
);

CommandShortcutEventHandler _emojiShortcutHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodeAtPath(selection.start.path);
  final context = node?.context;
  if (node == null ||
      context == null ||
      node.delta == null ||
      node.type == CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }
  final container = Overlay.of(context);
  emojiMenuService = EmojiMenu(editorState: editorState, overlay: container);
  emojiMenuService?.show('');
  return KeyEventResult.handled;
};
