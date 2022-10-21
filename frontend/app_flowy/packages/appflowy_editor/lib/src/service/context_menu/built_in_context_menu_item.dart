import 'package:appflowy_editor/src/service/context_menu/context_menu.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/copy_paste_handler.dart';

final builtInContextMenuItems = [
  [
    // cut
    ContextMenuItem(
      name: 'Cut',
      onPressed: (editorState) {
        cutEventHandler(editorState, null);
      },
    ),
    // copy
    ContextMenuItem(
      name: 'Copy',
      onPressed: (editorState) {
        copyEventHandler(editorState, null);
      },
    ),
    // Paste
    ContextMenuItem(
      name: 'Paste',
      onPressed: (editorState) {
        pasteEventHandler(editorState, null);
      },
    ),
  ],
];
