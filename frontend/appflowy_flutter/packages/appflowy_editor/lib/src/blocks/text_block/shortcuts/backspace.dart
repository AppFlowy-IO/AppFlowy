import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/shortcuts/block_shortcut.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

BlockShortcutHandler backspaceHandler = (context) {
  final editorState = Provider.of<EditorState>(context, listen: false);
  final selection = editorState.service.selectionServiceV2.selection;
  if (selection == null || !selection.isSingle) {
    return KeyEventResult.ignored;
  }

  final tr = editorState.transaction;
  final textNode =
      editorState.getNodesInSelection(selection).whereType<TextNode>().first;

  if (selection.isCollapsed) {
    final index = textNode.delta.prevRunePosition(selection.startIndex);
    if (index != -1) {
      tr.deleteText(
        textNode,
        index,
        selection.startIndex - index,
      );
    }
  }

  if (tr.operations.isNotEmpty) {
    editorState.apply(tr);
  }

  return KeyEventResult.handled;
};
