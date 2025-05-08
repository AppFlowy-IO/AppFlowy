import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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

    final transaction = this.transaction;

    // if current node is a paragraph and empty, replace it with the file block
    if (delta.isEmpty && node.type == ParagraphBlockKeys.type) {
      final insertedPath = path;
      transaction.insertNode(insertedPath, file);
      transaction.deleteNode(node);
    } else {
      // otherwise, insert the file block after the current node
      final insertedPath = path.next;
      transaction.insertNode(insertedPath, file);
    }

    return apply(transaction);
  }
}
