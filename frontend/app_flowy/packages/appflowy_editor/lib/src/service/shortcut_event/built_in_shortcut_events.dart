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
    handler: arrowKeysHandler,
  ),
  ShortcutEvent(
    key: 'Move cursor down',
    command: 'arrow down',
    handler: arrowKeysHandler,
  ),
  ShortcutEvent(
    key: 'Move cursor left',
    command: 'arrow left',
    handler: arrowKeysHandler,
  ),
  ShortcutEvent(
    key: 'Move cursor right',
    command: 'arrow right',
    handler: arrowKeysHandler,
  ),
  // TODO: split the keys.
  ShortcutEvent(
    key: 'Shift + Arrow Keys',
    command:
        'shift+arrow up,shift+arrow down,shift+arrow left,shift+arrow right',
    handler: arrowKeysHandler,
  ),
  ShortcutEvent(
    key: 'Control + Arrow Keys',
    command: 'meta+arrow up,meta+arrow down,meta+arrow left,meta+arrow right',
    windowsCommand:
        'ctrl+arrow up,ctrl+arrow down,ctrl+arrow left,ctrl+arrow right',
    macOSCommand: 'cmd+arrow up,cmd+arrow down,cmd+arrow left,cmd+arrow right',
    handler: arrowKeysHandler,
  ),
  ShortcutEvent(
    key: 'Meta + Shift + Arrow Keys',
    command:
        'meta+shift+arrow up,meta+shift+arrow down,meta+shift+arrow left,meta+shift+arrow right',
    windowsCommand:
        'ctrl+shift+arrow up,ctrl+shift+arrow down,ctrl+shift+arrow left,ctrl+shift+arrow right',
    macOSCommand:
        'cmd+shift+arrow up,cmd+shift+arrow down,cmd+shift+arrow left,cmd+shift+arrow right',
    handler: arrowKeysHandler,
  ),
  ShortcutEvent(
    key: 'Meta + Shift + Arrow Keys',
    command:
        'meta+shift+arrow up,meta+shift+arrow down,meta+shift+arrow left,meta+shift+arrow right',
    windowsCommand:
        'ctrl+shift+arrow up,ctrl+shift+arrow down,ctrl+shift+arrow left,ctrl+shift+arrow right',
    macOSCommand:
        'cmd+shift+arrow up,cmd+shift+arrow down,cmd+shift+arrow left,cmd+shift+arrow right',
    handler: arrowKeysHandler,
  ),
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
