import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/cupertino.dart';
import 'package:universal_platform/universal_platform.dart';

import 'emoji_menu.dart';

const _emojiCharacter = ':';
final _letterRegExp = RegExp(r'^[a-zA-Z]$');

CharacterShortcutEvent emojiCommand(BuildContext context) =>
    CharacterShortcutEvent(
      key: 'Opens Emoji Menu',
      character: '',
      regExp: _letterRegExp,
      handler: (editorState) async {
        return false;
      },
      handlerWithCharacter: (editorState, character) {
        emojiMenuService = EmojiMenu(
          overlay: Overlay.of(context),
          editorState: editorState,
        );
        return emojiCommandHandler(editorState, context, character);
      },
    );

EmojiMenuService? emojiMenuService;

Future<bool> emojiCommandHandler(
  EditorState editorState,
  BuildContext context,
  String character,
) async {
  final selection = editorState.selection;

  if (UniversalPlatform.isMobile || selection == null) {
    return false;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type == CodeBlockKeys.type) {
    return false;
  }

  if (selection.end.offset > 0) {
    final plain = delta.toPlainText();

    final previousCharacter = plain[selection.end.offset - 1];
    if (previousCharacter != _emojiCharacter) return false;
    if (!context.mounted) return false;

    if (!selection.isCollapsed) return false;

    await editorState.insertTextAtPosition(
      character,
      position: selection.start,
    );

    emojiMenuService?.show(character);
    return true;
  }

  return false;
}
