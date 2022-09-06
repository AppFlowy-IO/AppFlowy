// List<>

import 'package:appflowy_editor/src/service/internal_key_event_handlers/arrow_keys_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/backspace_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/copy_paste_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/enter_without_shift_in_text_node_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/page_up_down_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/redo_undo_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/select_all_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/slash_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/update_text_style_by_command_x_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/whitespace_handler.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event.dart';

//
List<ShortcutEvent> builtInShortcutEvents = [
  ShortcutEvent(
    key: 'Move cursor up',
    command: 'arrow up',
    handler: cursorUp,
  ),
  ShortcutEvent(
    key: 'Move cursor down',
    command: 'arrow down',
    handler: cursorDown,
  ),
  ShortcutEvent(
    key: 'Move cursor left',
    command: 'arrow left',
    handler: cursorLeft,
  ),
  ShortcutEvent(
    key: 'Move cursor right',
    command: 'arrow right',
    handler: cursorRight,
  ),
  ShortcutEvent(
    key: 'Cursor up select',
    command: 'shift+arrow up',
    handler: cursorUpSelect,
  ),
  ShortcutEvent(
    key: 'Cursor down select',
    command: 'shift+arrow down',
    handler: cursorDownSelect,
  ),
  ShortcutEvent(
    key: 'Cursor left select',
    command: 'shift+arrow left',
    handler: cursorLeftSelect,
  ),
  ShortcutEvent(
    key: 'Cursor right select',
    command: 'shift+arrow right',
    handler: cursorRightSelect,
  ),
  ShortcutEvent(
    key: 'Move cursor top',
    command: 'meta+arrow up',
    windowsCommand: 'ctrl+arrow up',
    handler: cursorBegin,
  ),
  ShortcutEvent(
    key: 'Move cursor bottom',
    command: 'meta+arrow down',
    windowsCommand: 'ctrl+arrow down',
    handler: cursorBottom,
  ),
  ShortcutEvent(
    key: 'Move cursor begin',
    command: 'meta+arrow left',
    windowsCommand: 'ctrl+arrow left',
    handler: cursorBegin,
  ),
  ShortcutEvent(
    key: 'Move cursor end',
    command: 'meta+arrow right',
    windowsCommand: 'ctrl+arrow right',
    handler: cursorEnd,
  ),
  ShortcutEvent(
    key: 'Cursor top select',
    command: 'meta+shift+arrow up',
    windowsCommand: 'ctrl+shift+arrow up',
    handler: cursorTopSelect,
  ),
  ShortcutEvent(
    key: 'Cursor bottom select',
    command: 'meta+shift+arrow down',
    windowsCommand: 'ctrl+shift+arrow down',
    handler: cursorBottomSelect,
  ),
  ShortcutEvent(
    key: 'Cursor begin select',
    command: 'meta+shift+arrow left',
    windowsCommand: 'ctrl+shift+arrow left',
    handler: cursorBeginSelect,
  ),
  ShortcutEvent(
    key: 'Cursor end select',
    command: 'meta+shift+arrow right',
    windowsCommand: 'ctrl+shift+arrow right',
    handler: cursorEndSelect,
  ),
  // TODO: split the keys.
  ShortcutEvent(
    key: 'Delete Text',
    command: 'delete,backspace',
    handler: deleteTextHandler,
  ),
  ShortcutEvent(
    key: 'selection menu',
    command: 'slash',
    handler: slashShortcutHandler,
  ),
  ShortcutEvent(
    key: 'copy / paste',
    command: 'meta+c,meta+v',
    windowsCommand: 'ctrl+c,ctrl+v',
    handler: copyPasteKeysHandler,
  ),
  ShortcutEvent(
    key: 'redo / undo',
    command: 'meta+z,meta+meta+shift+z',
    windowsCommand: 'ctrl+z,meta+ctrl+shift+z',
    handler: redoUndoKeysHandler,
  ),
  ShortcutEvent(
    key: 'enter',
    command: 'enter',
    handler: enterWithoutShiftInTextNodesHandler,
  ),
  ShortcutEvent(
    key: 'update text style',
    command: 'meta+b,meta+i,meta+u,meta+shift+s,meta+shift+h,meta+k',
    windowsCommand: 'ctrl+b,ctrl+i,ctrl+u,ctrl+shift+s,ctrl+shift+h,ctrl+k',
    handler: updateTextStyleByCommandXHandler,
  ),
  ShortcutEvent(
    key: 'markdown',
    command: 'space',
    handler: whiteSpaceHandler,
  ),
  ShortcutEvent(
    key: 'select all',
    command: 'meta+a',
    windowsCommand: 'ctrl+a',
    handler: selectAllHandler,
  ),
  ShortcutEvent(
    key: 'page up / page down',
    command: 'page up,page down',
    handler: pageUpDownHandler,
  ),
];
