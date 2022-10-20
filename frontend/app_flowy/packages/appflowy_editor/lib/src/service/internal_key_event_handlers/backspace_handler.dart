import 'package:appflowy_editor/src/infra/infra.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/number_list_helper.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

ShortcutEventHandler backspaceEventHandler = (editorState, event) {
  var selection = editorState.service.selectionService.currentSelection.value;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  var nodes = editorState.service.selectionService.currentSelectedNodes;
  nodes = selection.isBackward ? nodes : nodes.reversed.toList(growable: false);
  selection = selection.isBackward ? selection : selection.reversed;
  final textNodes = nodes.whereType<TextNode>().toList();
  final List<Node> nonTextNodes =
      nodes.where((node) => node is! TextNode).toList(growable: false);

  final transaction = editorState.transaction;
  List<int>? cancelNumberListPath;

  if (nonTextNodes.isNotEmpty) {
    transaction.deleteNodes(nonTextNodes);
  }

  if (textNodes.length == 1) {
    final textNode = textNodes.first;
    final index = textNode.delta.prevRunePosition(selection.start.offset);
    if (index < 0 && selection.isCollapsed) {
      // 1. style
      if (textNode.subtype != null) {
        if (textNode.subtype == BuiltInAttributeKey.numberList) {
          cancelNumberListPath = textNode.path;
        }
        transaction
          ..updateNode(textNode, {
            BuiltInAttributeKey.subtype: null,
            textNode.subtype!: null,
          })
          ..afterSelection = Selection.collapsed(
            Position(
              path: textNode.path,
              offset: 0,
            ),
          );
      } else {
        // 2. non-style
        // find previous text node.
        return _backDeleteToPreviousTextNode(
          editorState,
          textNode,
          transaction,
          nonTextNodes,
          selection,
        );
      }
    } else {
      if (selection.isCollapsed) {
        transaction.deleteText(
          textNode,
          index,
          selection.start.offset - index,
        );
      } else {
        transaction.deleteText(
          textNode,
          selection.start.offset,
          selection.end.offset - selection.start.offset,
        );
      }
    }
  } else {
    if (textNodes.isEmpty) {
      if (nonTextNodes.isNotEmpty) {
        transaction.afterSelection = Selection.collapsed(selection.start);
      }
      editorState.apply(transaction);
      return KeyEventResult.handled;
    }
    final startPosition = selection.start;
    final nodeAtStart = editorState.document.nodeAtPath(startPosition.path)!;
    _deleteTextNodes(transaction, textNodes, selection);
    editorState.apply(transaction);

    if (nodeAtStart is TextNode &&
        nodeAtStart.subtype == BuiltInAttributeKey.numberList) {
      makeFollowingNodesIncremental(
        editorState,
        startPosition.path,
        transaction.afterSelection!,
      );
    }
    return KeyEventResult.handled;
  }

  if (transaction.operations.isNotEmpty) {
    if (nonTextNodes.isNotEmpty) {
      transaction.afterSelection = Selection.collapsed(selection.start);
    }
    editorState.apply(transaction);
  }

  if (cancelNumberListPath != null) {
    makeFollowingNodesIncremental(
      editorState,
      cancelNumberListPath,
      Selection.collapsed(selection.start),
      beginNum: 0,
    );
  }

  return KeyEventResult.handled;
};

KeyEventResult _backDeleteToPreviousTextNode(
  EditorState editorState,
  TextNode textNode,
  Transaction transaction,
  List<Node> nonTextNodes,
  Selection selection,
) {
  if (textNode.next == null &&
      textNode.children.isEmpty &&
      textNode.parent?.parent != null) {
    transaction
      ..deleteNode(textNode)
      ..insertNode(textNode.parent!.path.next, textNode)
      ..afterSelection = Selection.collapsed(
        Position(path: textNode.parent!.path.next, offset: 0),
      );
    editorState.apply(transaction);
    return KeyEventResult.handled;
  }

  bool prevIsNumberList = false;
  final previousTextNode = Infra.forwardNearestTextNode(textNode);
  if (previousTextNode != null) {
    if (previousTextNode.subtype == BuiltInAttributeKey.numberList) {
      prevIsNumberList = true;
    }

    transaction.mergeText(previousTextNode, textNode);
    if (textNode.children.isNotEmpty) {
      transaction.insertNodes(
        previousTextNode.path.next,
        textNode.children.toList(growable: false),
      );
    }
    transaction.deleteNode(textNode);
    transaction.afterSelection = Selection.collapsed(
      Position(
        path: previousTextNode.path,
        offset: previousTextNode.toPlainText().length,
      ),
    );
  }

  if (transaction.operations.isNotEmpty) {
    if (nonTextNodes.isNotEmpty) {
      transaction.afterSelection = Selection.collapsed(selection.start);
    }
    editorState.apply(transaction);
  }

  if (prevIsNumberList) {
    makeFollowingNodesIncremental(
        editorState, previousTextNode!.path, transaction.afterSelection!);
  }

  return KeyEventResult.handled;
}

ShortcutEventHandler deleteEventHandler = (editorState, event) {
  var selection = editorState.service.selectionService.currentSelection.value;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  var nodes = editorState.service.selectionService.currentSelectedNodes;
  nodes = selection.isBackward ? nodes : nodes.reversed.toList(growable: false);
  selection = selection.isBackward ? selection : selection.reversed;
  // make sure all nodes is [TextNode].
  final textNodes = nodes.whereType<TextNode>().toList();
  if (textNodes.length != nodes.length) {
    return KeyEventResult.ignored;
  }

  final transaction = editorState.transaction;
  if (textNodes.length == 1) {
    final textNode = textNodes.first;
    // The cursor is at the end of the line,
    // merge next line into this line.
    if (selection.start.offset >= textNode.delta.length) {
      return _mergeNextLineIntoThisLine(
        editorState,
        textNode,
        transaction,
        selection,
      );
    }
    final index = textNode.delta.nextRunePosition(selection.start.offset);
    if (selection.isCollapsed) {
      transaction.deleteText(
        textNode,
        selection.start.offset,
        index - selection.start.offset,
      );
    } else {
      transaction.deleteText(
        textNode,
        selection.start.offset,
        selection.end.offset - selection.start.offset,
      );
    }
    editorState.apply(transaction);
  } else {
    final startPosition = selection.start;
    final nodeAtStart = editorState.document.nodeAtPath(startPosition.path)!;
    _deleteTextNodes(transaction, textNodes, selection);
    editorState.apply(transaction);

    if (nodeAtStart is TextNode &&
        nodeAtStart.subtype == BuiltInAttributeKey.numberList) {
      makeFollowingNodesIncremental(
          editorState, startPosition.path, transaction.afterSelection!);
    }
  }

  return KeyEventResult.handled;
};

KeyEventResult _mergeNextLineIntoThisLine(EditorState editorState,
    TextNode textNode, Transaction transaction, Selection selection) {
  final nextNode = textNode.next;
  if (nextNode == null) {
    return KeyEventResult.ignored;
  }
  if (nextNode is TextNode) {
    transaction.mergeText(textNode, nextNode);
  }
  transaction.deleteNode(nextNode);
  editorState.apply(transaction);

  if (textNode.subtype == BuiltInAttributeKey.numberList) {
    makeFollowingNodesIncremental(editorState, textNode.path, selection);
  }

  return KeyEventResult.handled;
}

void _deleteTextNodes(
    Transaction transaction, List<TextNode> textNodes, Selection selection) {
  final first = textNodes.first;
  final last = textNodes.last;
  var content = textNodes.last.toPlainText();
  content = content.substring(selection.end.offset, content.length);
  // Merge the fist and the last text node content,
  //  and delete the all nodes expect for the first.
  transaction
    ..deleteNodes(textNodes.sublist(1))
    ..mergeText(
      first,
      last,
      firstOffset: selection.start.offset,
      secondOffset: selection.end.offset,
    );
}
