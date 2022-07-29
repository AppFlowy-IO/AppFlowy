import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Handle delete text.
FlowyKeyEventHandler deleteTextHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.backspace) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.service.selectionService.currentSelection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  final nodes = editorState.service.selectionService.currentSelectedNodes.value;
  // make sure all nodes is [TextNode].
  final textNodes = nodes.whereType<TextNode>().toList();
  if (textNodes.length != nodes.length) {
    return KeyEventResult.ignored;
  }

  TransactionBuilder transactionBuilder = TransactionBuilder(editorState);
  if (textNodes.length == 1) {
    final textNode = textNodes.first;
    final index = selection.start.offset - 1;
    if (index < 0) {
      // 1. style
      if (textNode.subtype != null) {
        transactionBuilder.updateNode(textNode, {
          'subtype': null,
        });
      } else {
        // 2. non-style
        // find previous text node.
        while (textNode.previous != null) {
          if (textNode.previous is TextNode) {
            final previous = textNode.previous as TextNode;
            transactionBuilder
              ..deleteNode(textNode)
              ..insertText(
                previous,
                previous.toRawString().length,
                textNode.toRawString(),
              );
            // FIXME: keep the attributes.
            break;
          }
        }
      }
    } else {
      transactionBuilder.deleteText(
        textNode,
        selection.start.offset - 1,
        1,
      );
    }
  } else {
    for (var i = 0; i < textNodes.length; i++) {
      final textNode = textNodes[i];
      if (i == 0) {
        transactionBuilder.deleteText(
          textNode,
          selection.start.offset,
          textNode.toRawString().length - selection.start.offset,
        );
      } else if (i == textNodes.length - 1) {
        transactionBuilder.deleteText(
          textNode,
          0,
          selection.end.offset,
        );
      } else {
        transactionBuilder.deleteNode(textNode);
      }
    }
  }

  transactionBuilder.commit();

  return KeyEventResult.handled;
};
