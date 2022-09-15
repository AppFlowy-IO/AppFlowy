import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/document/node.dart';

ShortcutEventHandler formatBoldEventHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);
  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  formatBold(editorState);
  return KeyEventResult.handled;
};

ShortcutEventHandler formatItalicEventHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);
  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  formatItalic(editorState);
  return KeyEventResult.handled;
};

ShortcutEventHandler formatUnderlineEventHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);
  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  formatUnderline(editorState);
  return KeyEventResult.handled;
};

ShortcutEventHandler formatStrikethroughEventHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);
  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  formatStrikethrough(editorState);
  return KeyEventResult.handled;
};

ShortcutEventHandler formatHighlightEventHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);
  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  formatHighlight(
    editorState,
    editorState.editorStyle.textStyle.highlightColorHex,
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler formatLinkEventHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);
  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  if (editorState.service.toolbarService
          ?.triggerHandler('appflowy.toolbar.link') ==
      true) {
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler formatEmbedCodeEventHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);
  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  formatEmbedCode(editorState);
  return KeyEventResult.ignored;
};
