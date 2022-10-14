import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

ShortcutEventHandler tabHandler = (editorState, event) {
  // Only Supports BulletedList For Now.

  final selection = editorState.service.selectionService.currentSelection.value;
  final textNodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  if (textNodes.length != 1 || selection == null || !selection.isSingle) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final previous = textNode.previous;

  if (textNode.subtype != BuiltInAttributeKey.bulletedList) {
    final transaction = editorState.transaction
      ..insertText(textNode, selection.end.offset, ' ' * 4);
    editorState.apply(transaction);
    return KeyEventResult.handled;
  }

  if (previous == null ||
      previous.subtype != BuiltInAttributeKey.bulletedList) {
    return KeyEventResult.ignored;
  }

  final path = previous.path + [previous.children.length];
  final afterSelection = Selection(
    start: selection.start.copyWith(path: path),
    end: selection.end.copyWith(path: path),
  );
  final transaction = editorState.transaction
    ..deleteNode(textNode)
    ..insertNode(path, textNode)
    ..afterSelection = afterSelection;
  editorState.apply(transaction);

  return KeyEventResult.handled;
};
