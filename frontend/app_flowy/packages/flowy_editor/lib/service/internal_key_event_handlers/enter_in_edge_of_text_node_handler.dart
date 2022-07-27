import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/extensions/path_extensions.dart';
import 'package:flowy_editor/extensions/node_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    TransactionBuilder(editorState)
      ..insertNode(
        textNode.path.next,
        TextNode.empty(),
      )
      ..commit();
    return KeyEventResult.handled;
  } else if (textNode.selectable!.start() == selection.start) {
    TransactionBuilder(editorState)
      ..insertNode(
        textNode.path,
        TextNode.empty(),
      )
      ..commit();
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
};
