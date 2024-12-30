import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final mathEquationMobileToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, __, ___) => const SizedBox(
    width: 22,
    child: FlowySvg(FlowySvgs.math_lg),
  ),
  actionHandler: (_, editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final path = selection.start.path;
    final node = editorState.getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final transaction = editorState.transaction;
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

    await editorState.apply(transaction);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final mathEquationState =
          editorState.getNodeAtPath(path)?.key.currentState;
      if (mathEquationState != null &&
          mathEquationState is MathEquationBlockComponentWidgetState) {
        mathEquationState.showEditingDialog();
      }
    });
  },
);
