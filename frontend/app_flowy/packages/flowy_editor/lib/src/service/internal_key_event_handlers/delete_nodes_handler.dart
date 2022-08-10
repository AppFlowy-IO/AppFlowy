import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/src/service/keyboard_service.dart';
import 'package:flutter/material.dart';

FlowyKeyEventHandler flowyDeleteNodesHandler = (editorState, event) {
  // Handle delete nodes.
  final nodes = editorState.selectedNodes;
  if (nodes.length <= 1) {
    return KeyEventResult.ignored;
  }

  debugPrint('delete nodes = $nodes');

  nodes
      .fold<TransactionBuilder>(
        TransactionBuilder(editorState),
        (previousValue, node) => previousValue..deleteNode(node),
      )
      .commit();
  return KeyEventResult.handled;
};
