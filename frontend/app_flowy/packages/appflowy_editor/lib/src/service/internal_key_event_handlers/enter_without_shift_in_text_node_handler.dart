import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import './number_list_helper.dart';

/// Handle some cases where enter is pressed and shift is not pressed.
///
/// 1. Multiple selection and the selected nodes are [TextNode]
///   1.1 delete the nodes expect for the first and the last,
///     and delete the text in the first and the last node by case.
/// 2. Single selection and the selected node is [TextNode]
///   2.1 split the node into two nodes with style
///   2.2 or insert a empty text node before.
ShortcutEventHandler enterWithoutShiftInTextNodesHandler =
    (editorState, event) {
  var selection = editorState.service.selectionService.currentSelection.value;
  var nodes = editorState.service.selectionService.currentSelectedNodes;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  if (selection.isForward) {
    selection = selection.reversed;
    nodes = nodes.reversed.toList(growable: false);
  }
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);

  if (nodes.length != textNodes.length) {
    return KeyEventResult.ignored;
  }

  // Multiple selection
  if (!selection.isSingle) {
    final startNode = editorState.document.nodeAtPath(selection.start.path)!;
    final length = textNodes.length;
    final List<TextNode> subTextNodes =
        length >= 3 ? textNodes.sublist(1, textNodes.length - 1) : [];
    final afterSelection = Selection.collapsed(
      Position(path: textNodes.first.path.next, offset: 0),
    );
    editorState.transaction
      ..deleteText(
        textNodes.first,
        selection.start.offset,
        textNodes.first.toPlainText().length,
      )
      ..deleteNodes(subTextNodes)
      ..deleteText(
        textNodes.last,
        0,
        selection.end.offset,
      )
      ..afterSelection = afterSelection;
    editorState.commit();

    if (startNode is TextNode &&
        startNode.subtype == BuiltInAttributeKey.numberList) {
      makeFollowingNodesIncremental(
          editorState, selection.start.path, afterSelection);
    }

    return KeyEventResult.handled;
  }

  // Single selection and the selected node is [TextNode]
  if (textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;

  // If selection is collapsed and position.start.offset == 0,
  //  insert a empty text node before.
  if (selection.isCollapsed && selection.start.offset == 0) {
    if (textNode.toPlainText().isEmpty && textNode.subtype != null) {
      final afterSelection = Selection.collapsed(
        Position(path: textNode.path, offset: 0),
      );
      editorState.transaction
        ..updateNode(textNode, {
          BuiltInAttributeKey.subtype: null,
        })
        ..afterSelection = afterSelection;
      editorState.commit();

      final nextNode = textNode.next;
      if (nextNode is TextNode &&
          nextNode.subtype == BuiltInAttributeKey.numberList) {
        makeFollowingNodesIncremental(
            editorState, textNode.path, afterSelection,
            beginNum: 0);
      }
    } else {
      final subtype = textNode.subtype;
      final afterSelection = Selection.collapsed(
        Position(path: textNode.path.next, offset: 0),
      );

      if (subtype == BuiltInAttributeKey.numberList) {
        final prevNumber =
            textNode.attributes[BuiltInAttributeKey.number] as int;
        final newNode = TextNode.empty();
        newNode.attributes[BuiltInAttributeKey.subtype] =
            BuiltInAttributeKey.numberList;
        newNode.attributes[BuiltInAttributeKey.number] = prevNumber;
        final insertPath = textNode.path;
        editorState.transaction
          ..insertNode(
            insertPath,
            newNode,
          )
          ..afterSelection = afterSelection;
        editorState.commit();

        makeFollowingNodesIncremental(editorState, insertPath, afterSelection,
            beginNum: prevNumber);
      } else {
        bool needCopyAttributes = ![
          BuiltInAttributeKey.heading,
          BuiltInAttributeKey.quote,
        ].contains(subtype);
        editorState.transaction
          ..insertNode(
            textNode.path,
            textNode.copyWith(
              children: LinkedList(),
              delta: Delta(),
              attributes: needCopyAttributes ? null : {},
            ),
          )
          ..afterSelection = afterSelection;
        editorState.commit();
      }
    }
    return KeyEventResult.handled;
  }

  // Otherwise,
  //  split the node into two nodes with style
  Attributes attributes = _attributesFromPreviousLine(textNode);

  final nextPath = textNode.path.next;
  final afterSelection = Selection.collapsed(
    Position(path: nextPath, offset: 0),
  );

  final transaction = editorState.transaction;
  transaction.insertNode(
    textNode.path.next,
    textNode.copyWith(
      attributes: attributes,
      delta: textNode.delta.slice(selection.end.offset),
    ),
  );
  transaction.deleteText(
    textNode,
    selection.start.offset,
    textNode.toPlainText().length - selection.start.offset,
  );
  if (textNode.children.isNotEmpty) {
    final children = textNode.children.toList(growable: false);
    transaction.deleteNodes(children);
  }
  transaction.afterSelection = afterSelection;
  editorState.commit();

  // If the new type of a text node is number list,
  // the numbers of the following nodes should be incremental.
  if (textNode.subtype == BuiltInAttributeKey.numberList) {
    makeFollowingNodesIncremental(editorState, nextPath, afterSelection);
  }

  return KeyEventResult.handled;
};

Attributes _attributesFromPreviousLine(TextNode textNode) {
  final prevAttributes = textNode.attributes;
  final subType = textNode.subtype;
  if (subType == null ||
      subType == BuiltInAttributeKey.heading ||
      subType == BuiltInAttributeKey.quote) {
    return {};
  }

  final copy = Attributes.from(prevAttributes);
  if (subType == BuiltInAttributeKey.numberList) {
    return _nextNumberAttributesFromPreviousLine(copy, textNode);
  }

  if (subType == BuiltInAttributeKey.checkbox) {
    copy[BuiltInAttributeKey.checkbox] = false;
    return copy;
  }

  return copy;
}

Attributes _nextNumberAttributesFromPreviousLine(
    Attributes copy, TextNode textNode) {
  final prevNum = textNode.attributes[BuiltInAttributeKey.number] as int?;
  copy[BuiltInAttributeKey.number] = prevNum == null ? 1 : prevNum + 1;
  return copy;
}
