import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/table_const.dart';

ShortcutEvent enterInTableCell = ShortcutEvent(
  key: 'Don\'t add new line in table cell',
  command: 'enter',
  handler: _enterInTableCellHandler,
);

ShortcutEvent leftInTableCell = ShortcutEvent(
  key: 'Move to left cell if its at start of current cell',
  command: 'arrow left',
  handler: _leftInTableCellHandler,
);

ShortcutEvent rightInTableCell = ShortcutEvent(
  key: 'Move to right cell if its at the end of current cell',
  command: 'arrow right',
  handler: _rightInTableCellHandler,
);

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
      final cell = inTableNodes.first.parent!;
      final col = cell.attributes['position']['col'];
      final row = cell.attributes['position']['row'];
      final nextNode = cell.parent?.children.firstWhereOrNull((n) =>
          n.attributes['position']['col'] == col &&
          n.attributes['position']['row'] == row + 1);
      if (nextNode == null) {
        final transaction = editorState.transaction;
        transaction.insertNode(cell.parent!.path.next, TextNode.empty());
        transaction.afterSelection =
            Selection.single(path: cell.parent!.path.next, startOffset: 0);
        editorState.apply(transaction);
      } else if (nextNode.children.isNotEmpty &&
          nextNode.childAtIndex(0)! is TextNode) {
        editorState.service.selectionService.updateSelection(Selection.single(
            path: nextNode.childAtIndex(0)!.path, startOffset: 0));
      }
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler _leftInTableCellHandler = (editorState, event) {
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
    final cell = inTableNodes.first.parent!;
    final col = cell.attributes['position']['col'];
    final row = cell.attributes['position']['row'];
    final nextNode = cell.parent?.children.firstWhereOrNull((n) =>
        n.attributes['position']['col'] == col - 1 &&
        n.attributes['position']['row'] == row);
    if (nextNode != null &&
        nextNode.children.isNotEmpty &&
        nextNode.childAtIndex(0)! is TextNode) {
      final target = nextNode.childAtIndex(0)! as TextNode;
      editorState.service.selectionService.updateSelection(Selection.single(
          path: target.path, startOffset: target.delta.length));
    }

    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler _rightInTableCellHandler = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final inTableNodes = nodes
      .whereType<TextNode>()
      .where((node) => node.parent?.id.contains(kTableType) ?? false);
  final selection = editorState.service.selectionService.currentSelection.value;
  if (inTableNodes.isNotEmpty &&
      inTableNodes.length == 1 &&
      selection != null &&
      selection.isCollapsed &&
      selection.start.offset == inTableNodes.first.delta.length &&
      inTableNodes.first.parent?.id == 'table/cell') {
    final cell = inTableNodes.first.parent!;
    final col = cell.attributes['position']['col'];
    final row = cell.attributes['position']['row'];
    final nextNode = cell.parent?.children.firstWhereOrNull((n) =>
        n.attributes['position']['col'] == col + 1 &&
        n.attributes['position']['row'] == row);
    if (nextNode != null &&
        nextNode.children.isNotEmpty &&
        nextNode.childAtIndex(0)! is TextNode) {
      editorState.service.selectionService.updateSelection(Selection.single(
          path: nextNode.childAtIndex(0)!.path, startOffset: 0));
    }

    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
