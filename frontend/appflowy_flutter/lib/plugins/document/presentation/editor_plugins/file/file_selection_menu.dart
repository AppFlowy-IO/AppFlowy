import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension InsertFile on EditorState {
  Future<void> insertEmptyFileBlock(GlobalKey key) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final path = selection.end.path;
    final node = getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final file = fileNode(url: '')..extraInfos = {'global_key': key};

    final insertedPath = delta.isEmpty ? path : path.next;
    final transaction = this.transaction
      ..insertNode(insertedPath, file)
      ..insertNode(insertedPath, paragraphNode())
      ..afterSelection = Selection.collapsed(Position(path: insertedPath.next));

    return apply(transaction);
  }
}
