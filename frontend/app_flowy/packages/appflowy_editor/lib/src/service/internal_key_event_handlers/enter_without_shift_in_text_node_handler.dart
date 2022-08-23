import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_editor/src/document/attributes.dart';
import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/extensions/path_extensions.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/service/keyboard_service.dart';

/// Handle some cases where enter is pressed and shift is not pressed.
///
/// 1. Multiple selection and the selected nodes are [TextNode]
///   1.1 delete the nodes expect for the first and the last,
///     and delete the text in the first and the last node by case.
/// 2. Single selection and the selected node is [TextNode]
///   2.1 split the node into two nodes with style
///   2.2 or insert a empty text node before.
AppFlowyKeyEventHandler enterWithoutShiftInTextNodesHandler =
    (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.enter || event.isShiftPressed) {
    return KeyEventResult.ignored;
  }

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
    final length = textNodes.length;
    final List<TextNode> subTextNodes =
        length >= 3 ? textNodes.sublist(1, textNodes.length - 1) : [];
    final afterSelection = Selection.collapsed(
      Position(path: textNodes.first.path.next, offset: 0),
    );
    TransactionBuilder(editorState)
      ..deleteText(
        textNodes.first,
        selection.start.offset,
        textNodes.first.toRawString().length,
      )
      ..deleteNodes(subTextNodes)
      ..deleteText(
        textNodes.last,
        0,
        selection.end.offset,
      )
      ..afterSelection = afterSelection
      ..commit();
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
    if (textNode.toRawString().isEmpty && textNode.subtype != null) {
      final afterSelection = Selection.collapsed(
        Position(path: textNode.path, offset: 0),
      );
      TransactionBuilder(editorState)
        ..updateNode(
            textNode,
            Attributes.fromIterable(
              StyleKey.globalStyleKeys,
              value: (_) => null,
            ))
        ..afterSelection = afterSelection
        ..commit();
    } else {
      final afterSelection = Selection.collapsed(
        Position(path: textNode.path.next, offset: 0),
      );
      TransactionBuilder(editorState)
        ..insertNode(
          textNode.path,
          TextNode.empty(),
        )
        ..afterSelection = afterSelection
        ..commit();
    }
    return KeyEventResult.handled;
  }

  // Otherwise,
  //  split the node into two nodes with style
  final needCopyAttributes = StyleKey.globalStyleKeys
      .where((key) => key != StyleKey.heading)
      .contains(textNode.subtype);
  Attributes attributes = {};
  if (needCopyAttributes) {
    attributes = Attributes.from(textNode.attributes);
    if (attributes.check) {
      attributes[StyleKey.checkbox] = false;
    }
  }
  final afterSelection = Selection.collapsed(
    Position(path: textNode.path.next, offset: 0),
  );
  TransactionBuilder(editorState)
    ..insertNode(
      textNode.path.next,
      textNode.copyWith(
        attributes: attributes,
        delta: textNode.delta.slice(selection.end.offset),
      ),
    )
    ..deleteText(
      textNode,
      selection.start.offset,
      textNode.toRawString().length - selection.start.offset,
    )
    ..afterSelection = afterSelection
    ..commit();
  return KeyEventResult.handled;
};
