import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flowy_editor/extensions/node_extensions.dart';
import 'package:flowy_editor/extensions/path_extensions.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/service/keyboard_service.dart';

FlowyKeyEventHandler enterInEdgeOfTextNodeHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.enter) {
    return KeyEventResult.ignored;
  }

  final nodes = editorState.service.selectionService.currentSelectedNodes.value;
  final selection = editorState.service.selectionService.currentSelection;
  if (selection == null ||
      nodes.length != 1 ||
      nodes.first is! TextNode ||
      !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  final textNode = nodes.first as TextNode;
  if (textNode.selectable!.end() == selection.end) {
    final needCopyAttributes = StyleKey.globalStyleKeys
        .where((key) => key != StyleKey.heading)
        .contains(textNode.subtype);
    TransactionBuilder(editorState)
      ..insertNode(
        textNode.path.next,
        textNode.copyWith(
          children: LinkedList(),
          delta: Delta([TextInsert(' ')]),
          attributes:
              needCopyAttributes ? {StyleKey.subtype: textNode.subtype} : null,
        ),
      )
      ..commit();
    return KeyEventResult.handled;
  } else if (textNode.selectable!.start() == selection.start) {
    TransactionBuilder(editorState)
      ..insertNode(
        textNode.path,
        textNode.copyWith(
          children: LinkedList(),
          delta: Delta([TextInsert(' ')]),
          attributes: {},
        ),
      )
      ..commit();
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
};
