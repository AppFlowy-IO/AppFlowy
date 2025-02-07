import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:universal_platform/universal_platform.dart';

import 'emoji_menu.dart';

const emojiCharacter = ':';

CharacterShortcutEvent emojiCommand(BuildContext context) =>
    CharacterShortcutEvent(
      key: 'Opens Emoji Menu',
      character: emojiCharacter,
      handler: (editorState) {
        emojiMenuService ??= EmojiMenu(
          context: context,
          editorState: editorState,
        );
        return emojiCommandHandler(editorState, context);
      },
    );

EmojiMenuService? emojiMenuService;

Future<bool> emojiCommandHandler(
  EditorState editorState,
  BuildContext context,
) async {
  final selection = editorState.selection;

  if (UniversalPlatform.isMobile || selection == null) {
    return false;
  }

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  await editorState.insertTextAtPosition(
    emojiCharacter,
    position: selection.start,
  );
  emojiMenuService?.show();
  return true;
}
