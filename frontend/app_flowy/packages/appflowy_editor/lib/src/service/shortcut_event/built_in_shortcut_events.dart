// List<>

import 'package:appflowy_editor/src/service/internal_key_event_handlers/arrow_keys_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/backspace_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/copy_paste_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/enter_without_shift_in_text_node_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/markdown_syntax_to_styled_text.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/page_up_down_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/redo_undo_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/select_all_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/slash_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/format_style_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/space_on_web_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/tab_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/whitespace_handler.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event.dart';
import 'package:flutter/foundation.dart';

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
    linuxCommand: 'ctrl+arrow up',
    handler: cursorTop,
  ),
  ShortcutEvent(
    key: 'Move cursor bottom',
    command: 'meta+arrow down',
    windowsCommand: 'ctrl+arrow down',
    linuxCommand: 'ctrl+arrow down',
    handler: cursorBottom,
  ),
  ShortcutEvent(
    key: 'Move cursor begin',
    command: 'meta+arrow left',
    windowsCommand: 'ctrl+arrow left',
    linuxCommand: 'ctrl+arrow left',
    handler: cursorBegin,
  ),
  ShortcutEvent(
    key: 'Move cursor end',
    command: 'meta+arrow right',
    windowsCommand: 'ctrl+arrow right',
    linuxCommand: 'ctrl+arrow right',
    handler: cursorEnd,
  ),
  ShortcutEvent(
    key: 'Cursor top select',
    command: 'meta+shift+arrow up',
    windowsCommand: 'ctrl+shift+arrow up',
    linuxCommand: 'ctrl+shift+arrow up',
    handler: cursorTopSelect,
  ),
  ShortcutEvent(
    key: 'Cursor bottom select',
    command: 'meta+shift+arrow down',
    windowsCommand: 'ctrl+shift+arrow down',
    linuxCommand: 'ctrl+shift+arrow down',
    handler: cursorBottomSelect,
  ),
  ShortcutEvent(
    key: 'Cursor begin select',
    command: 'meta+shift+arrow left',
    windowsCommand: 'ctrl+shift+arrow left',
    linuxCommand: 'ctrl+shift+arrow left',
    handler: cursorBeginSelect,
  ),
  ShortcutEvent(
    key: 'Cursor end select',
    command: 'meta+shift+arrow right',
    windowsCommand: 'ctrl+shift+arrow right',
    linuxCommand: 'ctrl+shift+arrow right',
    handler: cursorEndSelect,
  ),
  ShortcutEvent(
    key: 'Redo',
    command: 'meta+shift+z',
    windowsCommand: 'ctrl+shift+z',
    linuxCommand: 'ctrl+shift+z',
    handler: redoEventHandler,
  ),
  ShortcutEvent(
    key: 'Undo',
    command: 'meta+z',
    windowsCommand: 'ctrl+z',
    linuxCommand: 'ctrl+z',
    handler: undoEventHandler,
  ),
  ShortcutEvent(
    key: 'Format bold',
    command: 'meta+b',
    windowsCommand: 'ctrl+b',
    linuxCommand: 'ctrl+b',
    handler: formatBoldEventHandler,
  ),
  ShortcutEvent(
    key: 'Format italic',
    command: 'meta+i',
    windowsCommand: 'ctrl+i',
    linuxCommand: 'ctrl+i',
    handler: formatItalicEventHandler,
  ),
  ShortcutEvent(
    key: 'Format underline',
    command: 'meta+u',
    windowsCommand: 'ctrl+u',
    linuxCommand: 'ctrl+u',
    handler: formatUnderlineEventHandler,
  ),
  ShortcutEvent(
    key: 'Format strikethrough',
    command: 'meta+shift+s',
    windowsCommand: 'ctrl+shift+s',
    linuxCommand: 'ctrl+shift+s',
    handler: formatStrikethroughEventHandler,
  ),
  ShortcutEvent(
    key: 'Format highlight',
    command: 'meta+shift+h',
    windowsCommand: 'ctrl+shift+h',
    linuxCommand: 'ctrl+shift+h',
    handler: formatHighlightEventHandler,
  ),
  ShortcutEvent(
    key: 'Format embed code',
    command: 'meta+e',
    windowsCommand: 'ctrl+e',
    linuxCommand: 'ctrl+e',
    handler: formatEmbedCodeEventHandler,
  ),
  ShortcutEvent(
    key: 'Format link',
    command: 'meta+k',
    windowsCommand: 'ctrl+k',
    linuxCommand: 'ctrl+k',
    handler: formatLinkEventHandler,
  ),
  ShortcutEvent(
    key: 'Copy',
    command: 'meta+c',
    windowsCommand: 'ctrl+c',
    linuxCommand: 'ctrl+c',
    handler: copyEventHandler,
  ),
  ShortcutEvent(
    key: 'Paste',
    command: 'meta+v',
    windowsCommand: 'ctrl+v',
    linuxCommand: 'ctrl+v',
    handler: pasteEventHandler,
  ),
  ShortcutEvent(
    key: 'Cut',
    command: 'meta+x',
    windowsCommand: 'ctrl+x',
    linuxCommand: 'ctrl+x',
    handler: cutEventHandler,
  ),
  ShortcutEvent(
    key: 'Home',
    command: 'home',
    handler: cursorBegin,
  ),
  ShortcutEvent(
    key: 'End',
    command: 'end',
    handler: cursorEnd,
  ),
  ShortcutEvent(
    key: 'Delete Text by backspace',
    command: 'backspace',
    handler: backspaceEventHandler,
  ),
  ShortcutEvent(
    key: 'Delete Text',
    command: 'delete',
    handler: deleteEventHandler,
  ),
  ShortcutEvent(
    key: 'selection menu',
    command: 'slash',
    handler: slashShortcutHandler,
  ),
  ShortcutEvent(
    key: 'enter',
    command: 'enter',
    handler: enterWithoutShiftInTextNodesHandler,
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
    linuxCommand: 'ctrl+a',
    handler: selectAllHandler,
  ),
  ShortcutEvent(
    key: 'Page up',
    command: 'page up',
    handler: pageUpHandler,
  ),
  ShortcutEvent(
    key: 'Page down',
    command: 'page down',
    handler: pageDownHandler,
  ),
  ShortcutEvent(
    key: 'Tab',
    command: 'tab',
    handler: tabHandler,
  ),
  ShortcutEvent(
    key: 'Double stars to bold',
    command: 'shift+asterisk',
    handler: doubleAsterisksToBold,
  ),
  ShortcutEvent(
    key: 'Double underscores to bold',
    command: 'shift+underscore',
    handler: doubleUnderscoresToBold,
  ),
  ShortcutEvent(
    key: 'Backquote to code',
    command: 'backquote',
    handler: backquoteToCodeHandler,
  ),
  ShortcutEvent(
    key: 'Double tilde to strikethrough',
    command: 'shift+tilde',
    handler: doubleTildeToStrikethrough,
  ),
  ShortcutEvent(
    key: 'Markdown link to link',
    command: 'shift+parenthesis right',
    handler: markdownLinkToLinkHandler,
  ),
  // https://github.com/flutter/flutter/issues/104944
  // Workaround: Using space editing on the web platform often results in errors,
  //  so adding a shortcut event to handle the space input instead of using the
  //  `input_service`.
  if (kIsWeb)
    ShortcutEvent(
      key: 'Space on the Web',
      command: 'space',
      handler: spaceOnWebHandler,
    ),
];
