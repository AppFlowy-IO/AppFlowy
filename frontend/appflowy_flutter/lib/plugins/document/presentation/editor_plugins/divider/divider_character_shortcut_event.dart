import 'package:appflowy/plugins/document/presentation/editor_plugins/divider/divider_node_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// insert divider into a document by typing three minuses(-).
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CharacterShortcutEvent insertDividerCommand = CharacterShortcutEvent(
  key: 'insert a divider',
  character: '-',
  handler: _insertDividerCommandHandler,
);

CharacterShortcutEventHandler _insertDividerCommandHandler =
    (editorState) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }
  final path = selection.end.path;
  final node = editorState.getNodeAtPath(path);
  final delta = node?.delta;
  if (node == null || delta == null) {
    return false;
  }
  if (delta.toPlainText() != '--') {
    return false;
  }
  final transaction = editorState.transaction
    ..insertNode(path, dividerNode())
    ..deleteNode(node);
  // remove the existing minuses.

  editorState.apply(transaction);
  return true;
};

SelectionMenuItem dividerMenuItem = SelectionMenuItem(
  name: 'Divider',
  icon: (editorState, onSelected) => const Icon(
    Icons.horizontal_rule,
    size: 18.0,
  ),
  keywords: ['horizontal rule', 'divider'],
  handler: (editorState, _, __) {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final path = selection.end.path;
    final node = editorState.getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final insertedPath = delta.isEmpty ? path : path.next;
    final transaction = editorState.transaction
      ..insertNode(insertedPath, dividerNode());
    editorState.apply(transaction);
  },
);
