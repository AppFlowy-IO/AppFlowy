import 'package:flowy_editor/src/document/node.dart';
import 'package:flowy_editor/src/document/position.dart';
import 'package:flowy_editor/src/document/selection.dart';
import 'package:flowy_editor/src/operation/transaction_builder.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/src/service/keyboard_service.dart';
import 'package:flowy_editor/src/extensions/path_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FlowyKeyEventHandler tabHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.tab) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.service.selectionService.currentSelection.value;
  final textNodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();

  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  // Only supports bulleted list now.
  final textNode = textNodes.first;
  if (textNode.subtype != StyleKey.bulletedList) {
    return KeyEventResult.ignored;
  }

  final builder = TransactionBuilder(editorState);

  // Tab = Move the current node to the child of its previous node
  final previous = textNode.previous;

  if (event.isShiftPressed) {
    // Make sure the textNode' parent is not root.
    if (textNode.parent != null && textNode.parent!.parent != null) {
      final path = textNode.parent!.path.next;
      List<Node> followedNodes = [];
      var followedNode = textNode.next;
      while (followedNode != null) {
        followedNodes.add(followedNode);
        followedNode = followedNode.next;
      }
      builder
        ..deleteNodes([textNode, ...followedNodes])
        ..insertNodes(path, [textNode, ...followedNodes])
        ..afterSelection = Selection.collapsed(
          Position(path: path, offset: selection.end.offset),
        )
        ..commit();
      return KeyEventResult.handled;
    }
  } else {
    if (previous != null && selection.isCollapsed) {
      final path = previous.children.isEmpty
          ? previous.path + [0]
          : previous.children.last.path.next;

      builder
        ..deleteNode(textNode)
        ..insertNode(path, textNode)
        ..afterSelection = Selection.collapsed(
          Position(path: path, offset: selection.end.offset),
        )
        ..commit();
      return KeyEventResult.handled;
    }
  }

  return KeyEventResult.ignored;
};
