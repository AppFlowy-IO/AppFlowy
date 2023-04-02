import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/text_block/shortcuts/backspace.dart';
import 'package:appflowy_editor/src/block/text_block/shortcuts/slash.dart';
import 'package:flutter/material.dart';

final List<ShortcutEvent> textBlockShortcuts = [
  ShortcutEvent(
    key: 'text_block.backspace',
    command: 'backspace',
    blockShortcutHandler: backspaceHandler,
    handler: (editorState, event) => KeyEventResult.ignored,
  ),
  ShortcutEvent(
    key: 'text_block.slash',
    character: '/',
    blockShortcutHandler: slashHandler,
    handler: (editorState, event) => KeyEventResult.ignored,
  ),
];
