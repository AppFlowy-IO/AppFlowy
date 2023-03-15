import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';

ShortcutEvent enterInTableCell = ShortcutEvent(
  key: 'Don\'t add new line in table cell',
  command: 'enter',
  handler: _enterInTableCellHandler,
);

/*ShortcutEvent leftInTableCell = ShortcutEvent(
  key: 'Move to left cell if its at start of current cell',
  command: 'arrow left',
  handler: _leftInTableCellHandler,
);

ShortcutEvent rightInTableCell = ShortcutEvent(
  key: 'Move to right cell if its at the end of current cell',
  command: 'arrow right',
  handler: _rightInTableCellHandler,
);*/

ShortcutEventHandler _enterInTableCellHandler = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final inTableNodes = nodes
      .whereType<TextNode>()
      .where((node) => node.parent?.id.contains(kTableType) ?? false);
  if (inTableNodes.isNotEmpty) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    if (inTableNodes.length == 1 &&
        selection != null &&
        selection.isCollapsed &&
        inTableNodes.first.parent?.id == 'table/cell') {
      final transaction = editorState.transaction;
      final nextNode = inTableNodes.first.parent!.next;
      if (nextNode == null) {
        transaction.insertNode(
            inTableNodes.first.parent!.parent!.path.next, TextNode.empty());
        transaction.afterSelection = Selection.single(
            path: inTableNodes.first.parent!.parent!.path.next, startOffset: 0);
      } else if (nextNode.children.isNotEmpty &&
          nextNode.childAtIndex(0)! is TextNode) {
        transaction.afterSelection = Selection.single(
            path: nextNode.childAtIndex(0)!.path, startOffset: 0);
      }

      editorState.apply(transaction);
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

// TODO(zoli): how to get how many row/cols a table node has?
/*ShortcutEventHandler _leftInTableCellHandler = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final inTableNodes = nodes
      .whereType<TextNode>()
      .where((node) => node.parent?.id.contains(kTableType) ?? false);
  final selection = editorState.service.selectionService.currentSelection.value;
  if (inTableNodes.isNotEmpty &&
      inTableNodes.length == 1 &&
      selection != null &&
      selection.isCollapsed &&
      selection.start.offset == 0 &&
      inTableNodes.first.parent?.id == 'table/cell') {
    final transaction = editorState.transaction;

    editorState.apply(transaction);
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler _rightInTableCellHandler = (editorState, event) {
  return KeyEventResult.ignored;
};*/
