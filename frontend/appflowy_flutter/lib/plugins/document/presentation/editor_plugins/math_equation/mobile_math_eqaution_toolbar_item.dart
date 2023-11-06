import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/src/widgets/basic.dart';

final mathEquationMobileToolbarItem = MobileToolbarItem.action(
  itemIcon: const SizedBox(width: 22, child: FlowySvg(FlowySvgs.math_lg)),
  actionHandler: (editorState, selection) async {
    if (!selection.isCollapsed) {
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

    editorState.apply(transaction);
  },
);
