import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension EditorStateAddBlock on EditorState {
  Future<void> insertMathEquation(
    Selection selection,
  ) async {
    final path = selection.start.path;
    final node = getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final transaction = this.transaction;
    final insertedNode = mathEquationNode();
    if (delta.isEmpty) {
      transaction
        ..insertNode(path, insertedNode)
        ..deleteNode(node);
    } else {
      transaction.insertNode(
        path.next,
        insertedNode,
      );
    }

    await apply(transaction);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final mathEquationState = getNodeAtPath(path)?.key.currentState;
      if (mathEquationState != null &&
          mathEquationState is MathEquationBlockComponentWidgetState) {
        mathEquationState.showEditingDialog();
      }
    });
  }

  Future<void> insertDivider(Selection selection) async {
    // same as the [handler] of [dividerMenuItem] in Desktop

    final path = selection.end.path;
    final node = getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final insertedPath = delta.isEmpty ? path : path.next;
    final transaction = this.transaction;
    transaction.insertNode(insertedPath, dividerNode());
    // only insert a new paragraph node when the next node is not a paragraph node
    //  and its delta is not empty.
    final next = node.next;
    if (next == null ||
        next.type != ParagraphBlockKeys.type ||
        next.delta?.isNotEmpty == true) {
      transaction.insertNode(
        insertedPath,
        paragraphNode(),
      );
    }
    transaction.selectionExtraInfo = {};
    transaction.afterSelection = Selection.collapsed(
      Position(path: insertedPath.next),
    );
    await apply(transaction);
  }
}
