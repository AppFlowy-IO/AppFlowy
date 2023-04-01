import 'package:appflowy_editor_plugins/src/table/src/util.dart';
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

ShortcutEvent upInTableCell = ShortcutEvent(
  key: 'Move to up cell at same offset',
  command: 'arrow up',
  handler: _upInTableCellHandler,
);

ShortcutEvent downInTableCell = ShortcutEvent(
  key: 'Move to down cell at same offset',
  command: 'arrow down',
  handler: _downInTableCellHandler,
);

ShortcutEventHandler _enterInTableCellHandler = (editorState, event) {
  final inTableNodes = _inTableNodes(editorState);
  if (inTableNodes.isNotEmpty) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    if (_hasSelectionAndTableCell(inTableNodes, selection)) {
      final cell = inTableNodes.first.parent!;
      final nextNode = _getNextNode(inTableNodes, 0, 1);

      if (nextNode == null) {
        final transaction = editorState.transaction;
        transaction.insertNode(cell.parent!.path.next, TextNode.empty());
        transaction.afterSelection =
            Selection.single(path: cell.parent!.path.next, startOffset: 0);
        editorState.apply(transaction);
      } else if (_nodeHasTextChild(nextNode)) {
        editorState.service.selectionService.updateSelection(Selection.single(
            path: nextNode.childAtIndex(0)!.path, startOffset: 0));
      }
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler _leftInTableCellHandler = (editorState, event) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.service.selectionService.currentSelection.value;
  if (_hasSelectionAndTableCell(inTableNodes, selection) &&
      selection!.start.offset == 0) {
    final nextNode = _getNextNode(inTableNodes, -1, 0);

    if (_nodeHasTextChild(nextNode)) {
      final target = nextNode!.childAtIndex(0)! as TextNode;
      editorState.service.selectionService.updateSelection(Selection.single(
          path: target.path, startOffset: target.delta.length));
    }

    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler _rightInTableCellHandler = (editorState, event) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.service.selectionService.currentSelection.value;
  if (_hasSelectionAndTableCell(inTableNodes, selection) &&
      selection!.start.offset == inTableNodes.first.delta.length) {
    final nextNode = _getNextNode(inTableNodes, 1, 0);

    if (_nodeHasTextChild(nextNode)) {
      editorState.service.selectionService.updateSelection(Selection.single(
          path: nextNode!.childAtIndex(0)!.path, startOffset: 0));
    }

    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler _upInTableCellHandler = (editorState, event) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.service.selectionService.currentSelection.value;
  if (_hasSelectionAndTableCell(inTableNodes, selection)) {
    final nextNode = _getNextNode(inTableNodes, 0, -1);

    if (_nodeHasTextChild(nextNode)) {
      final target = nextNode!.childAtIndex(0)! as TextNode;
      final off = target.delta.length > selection!.start.offset
          ? selection.start.offset
          : target.delta.length;
      editorState.service.selectionService.updateSelection(
          Selection.single(path: target.path, startOffset: off));
    }

    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

ShortcutEventHandler _downInTableCellHandler = (editorState, event) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.service.selectionService.currentSelection.value;
  if (_hasSelectionAndTableCell(inTableNodes, selection)) {
    final nextNode = _getNextNode(inTableNodes, 0, 1);

    if (_nodeHasTextChild(nextNode)) {
      final target = nextNode!.childAtIndex(0)! as TextNode;
      final off = target.delta.length > selection!.start.offset
          ? selection.start.offset
          : target.delta.length;
      editorState.service.selectionService.updateSelection(
          Selection.single(path: target.path, startOffset: off));
    }

    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

Iterable<TextNode> _inTableNodes(EditorState editorState) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  return nodes
      .whereType<TextNode>()
      .where((node) => node.parent?.id.contains(kTableType) ?? false);
}

bool _hasSelectionAndTableCell(
        Iterable<TextNode> nodes, Selection? selection) =>
    nodes.length == 1 &&
    selection != null &&
    selection.isCollapsed &&
    nodes.first.parent?.id == 'table/cell';

Node? _getNextNode(Iterable<TextNode> nodes, int colDiff, rowDiff) {
  final cell = nodes.first.parent!;
  final col = cell.attributes['position']['col'];
  final row = cell.attributes['position']['row'];
  return cell.parent != null
      ? getCellNode(cell.parent!, col + colDiff, row + rowDiff)
      : null;
}

bool _nodeHasTextChild(Node? n) =>
    n != null && n.children.isNotEmpty && n.childAtIndex(0)! is TextNode;
