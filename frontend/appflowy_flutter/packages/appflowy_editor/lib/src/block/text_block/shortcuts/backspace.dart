import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/base_component/infra/text_block_infra.dart';
import 'package:appflowy_editor/src/block/base_component/shortcuts/block_shortcut.dart';
import 'package:appflowy_editor/src/command/text_block_command.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

TextBlockShortcutHandler backspaceHandler = (context, _) {
  final editorState = Provider.of<EditorState>(context, listen: false);
  final selection = editorState.service.selectionServiceV2.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  final tr = editorState.transaction;
  final node = editorState.getNodesInSelection(selection).first;
  if (selection.startIndex != 0) {
    tr.deleteTextWithSelection(node, selection);
  } else {
    if (node.next != null) {
      final mergedNode = TextBlockInfra.previousNodeContainsDelta(node);
      if (mergedNode != null) {
        tr.mergeTextIntoNode(node, mergedNode);
      }
    } else {
      if (node.parent != null && node.parent?.type != 'editor') {
        tr.moveToParentsSibling(node);
      }
    }
  }
  editorState.apply(tr);
  return KeyEventResult.handled;
};
