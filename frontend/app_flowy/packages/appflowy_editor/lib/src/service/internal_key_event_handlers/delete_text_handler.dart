import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_editor/appflowy_editor.dart';

KeyEventResult _handleBackspace(EditorState editorState, RawKeyEvent event) {
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

  final transactionBuilder = TransactionBuilder(editorState);
  if (textNodes.length == 1) {
    final textNode = textNodes.first;
    final index = textNode.delta.prevRunePosition(selection.start.offset);
    if (index < 0 && selection.isCollapsed) {
      // 1. style
      if (textNode.subtype != null) {
        transactionBuilder
          ..updateNode(textNode, {
            'subtype': null,
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
        while (textNode.previous != null) {
          if (textNode.previous is TextNode) {
            final previous = textNode.previous as TextNode;
            transactionBuilder
              ..mergeText(previous, textNode)
              ..deleteNode(textNode)
              ..afterSelection = Selection.collapsed(
                Position(
                  path: previous.path,
                  offset: previous.toRawString().length,
                ),
              );
            break;
          }
        }
      }
    } else {
      if (selection.isCollapsed) {
        transactionBuilder.deleteText(
          textNode,
          index,
          selection.start.offset - index,
        );
      } else {
        transactionBuilder.deleteText(
          textNode,
          selection.start.offset,
          selection.end.offset - selection.start.offset,
        );
      }
    }
  } else {
    _deleteNodes(transactionBuilder, textNodes, selection);
  }

  if (transactionBuilder.operations.isNotEmpty) {
    transactionBuilder.commit();
  }

  return KeyEventResult.handled;
}

KeyEventResult _handleDelete(EditorState editorState, RawKeyEvent event) {
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

  final transactionBuilder = TransactionBuilder(editorState);
  if (textNodes.length == 1) {
    final textNode = textNodes.first;
    if (selection.start.offset >= textNode.delta.length) {
      debugPrint("merge next line");
      final nextNode = textNode.next;
      if (nextNode == null) {
        return KeyEventResult.ignored;
      }
      if (nextNode is TextNode) {
        transactionBuilder.mergeText(textNode, nextNode);
      }
      transactionBuilder.deleteNode(nextNode);
    } else {
      final index = textNode.delta.nextRunePosition(selection.start.offset);
      if (selection.isCollapsed) {
        transactionBuilder.deleteText(
          textNode,
          selection.start.offset,
          index - selection.start.offset,
        );
      } else {
        transactionBuilder.deleteText(
          textNode,
          selection.start.offset,
          selection.end.offset - selection.start.offset,
        );
      }
    }
  } else {
    _deleteNodes(transactionBuilder, textNodes, selection);
  }

  transactionBuilder.commit();

  return KeyEventResult.handled;
}

void _deleteNodes(TransactionBuilder transactionBuilder,
    List<TextNode> textNodes, Selection selection) {
  final first = textNodes.first;
  final last = textNodes.last;
  var content = textNodes.last.toRawString();
  content = content.substring(selection.end.offset, content.length);
  // Merge the fist and the last text node content,
  //  and delete the all nodes expect for the first.
  transactionBuilder
    ..deleteNodes(textNodes.sublist(1))
    ..mergeText(
      first,
      last,
      firstOffset: selection.start.offset,
      secondOffset: selection.end.offset,
    );
}

// Handle delete text.
FlowyKeyEventHandler deleteTextHandler = (editorState, event) {
  if (event.logicalKey == LogicalKeyboardKey.backspace) {
    return _handleBackspace(editorState, event);
  }
  if (event.logicalKey == LogicalKeyboardKey.delete) {
    return _handleDelete(editorState, event);
  }

  return KeyEventResult.ignored;
};
