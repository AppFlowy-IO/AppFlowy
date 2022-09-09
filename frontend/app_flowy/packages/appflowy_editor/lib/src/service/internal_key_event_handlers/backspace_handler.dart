import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/number_list_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_editor/appflowy_editor.dart';

// Handle delete text.
ShortcutEventHandler deleteTextHandler = (editorState, event) {
  if (event.logicalKey == LogicalKeyboardKey.backspace) {
    return _handleBackspace(editorState, event);
  }
  if (event.logicalKey == LogicalKeyboardKey.delete) {
    return _handleDelete(editorState, event);
  }

  return KeyEventResult.ignored;
};

KeyEventResult _handleBackspace(EditorState editorState, RawKeyEvent event) {
  var selection = editorState.service.selectionService.currentSelection.value;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  var nodes = editorState.service.selectionService.currentSelectedNodes;
  nodes = selection.isBackward ? nodes : nodes.reversed.toList(growable: false);
  selection = selection.isBackward ? selection : selection.reversed;
  final textNodes = nodes.whereType<TextNode>().toList();
  final nonTextNodes =
      nodes.where((node) => node is! TextNode).toList(growable: false);

  final transactionBuilder = TransactionBuilder(editorState);
  List<int>? cancelNumberListPath;

  if (nonTextNodes.isNotEmpty) {
    transactionBuilder.deleteNodes(nonTextNodes);
  }

  if (textNodes.length == 1) {
    final textNode = textNodes.first;
    final index = textNode.delta.prevRunePosition(selection.start.offset);
    if (index < 0 && selection.isCollapsed) {
      // 1. style
      if (textNode.subtype != null) {
        if (textNode.subtype == StyleKey.numberList) {
          cancelNumberListPath = textNode.path;
        }
        transactionBuilder
          ..updateNode(textNode, {
            StyleKey.subtype: null,
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
        var previous = textNode.previous;
        while (previous != null) {
          if (previous is TextNode) {
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
          } else {
            previous = previous.previous;
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
    if (textNodes.isEmpty) {
      return KeyEventResult.handled;
    }
    final startPosition = selection.start;
    final nodeAtStart = editorState.document.nodeAtPath(startPosition.path)!;
    _deleteTextNodes(transactionBuilder, textNodes, selection);
    transactionBuilder.commit();

    if (nodeAtStart is TextNode && nodeAtStart.subtype == StyleKey.numberList) {
      makeFollowingNodesIncremental(
          editorState, startPosition.path, transactionBuilder.afterSelection!);
    }
    return KeyEventResult.handled;
  }

  if (transactionBuilder.operations.isNotEmpty) {
    if (nonTextNodes.isNotEmpty) {
      transactionBuilder.afterSelection = Selection.collapsed(selection.start);
    }
    transactionBuilder.commit();
  }

  if (cancelNumberListPath != null) {
    makeFollowingNodesIncremental(
        editorState, cancelNumberListPath, Selection.collapsed(selection.start),
        beginNum: 0);
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
    transactionBuilder.commit();
  } else {
    final startPosition = selection.start;
    final nodeAtStart = editorState.document.nodeAtPath(startPosition.path)!;
    _deleteTextNodes(transactionBuilder, textNodes, selection);
    transactionBuilder.commit();

    if (nodeAtStart is TextNode && nodeAtStart.subtype == StyleKey.numberList) {
      makeFollowingNodesIncremental(
          editorState, startPosition.path, transactionBuilder.afterSelection!);
    }
  }

  return KeyEventResult.handled;
}

void _deleteTextNodes(TransactionBuilder transactionBuilder,
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
