import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';

import 'package:flutter/services.dart';

ShortcutEventHandler updateTextStyleByCommandXHandler = (editorState, event) {
  if (!event.isMetaPressed) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);

  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }

  if (event.logicalKey == LogicalKeyboardKey.keyB) {
    formatBold(editorState);
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
    formatItalic(editorState);
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
    formatUnderline(editorState);
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.keyS &&
      event.isShiftPressed) {
    formatStrikethrough(editorState);
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.keyH &&
      event.isShiftPressed) {
    formatHighlight(editorState);
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
    if (editorState.service.toolbarService
            ?.triggerHandler('appflowy.toolbar.link') ==
        true) {
      return KeyEventResult.handled;
    }
  }

  return KeyEventResult.ignored;
};
