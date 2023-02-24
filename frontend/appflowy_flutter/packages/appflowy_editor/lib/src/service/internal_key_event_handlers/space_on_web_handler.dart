import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

ShortcutEventHandler spaceOnWebHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final textNodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>()
      .toList(growable: false);
  if (selection == null ||
      !selection.isCollapsed ||
      !kIsWeb ||
      textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  editorState.insertText(
    selection.startIndex,
    ' ',
    textNode: textNodes.first,
  );

  return KeyEventResult.handled;
};
