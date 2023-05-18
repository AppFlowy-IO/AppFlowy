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
final CharacterShortcutEvent convertMinusesToDivider = CharacterShortcutEvent(
  key: 'insert a divider',
  character: '-',
  handler: _convertMinusesToDividerHandler,
);

CharacterShortcutEventHandler _convertMinusesToDividerHandler =
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
  if (!_hasTwoConsecutiveDashes(node.delta!.toPlainText(), selection.start.offset)) {
    return false;
  }
  final dashStartPosition = selection.start.offset - 2;
  Transaction transaction;

  if (node.delta!.length > 2) {
    transaction = editorState.transaction
      ..deleteText(node, dashStartPosition, 2)
      ..insertNode(selection.end.path.next, dividerNode());
  } else {
    transaction = editorState.transaction
      ..insertNode(path, dividerNode())
      ..insertNode(path, paragraphNode())
      ..deleteNode(node)
      ..afterSelection = Selection.collapse(path.next, 0);
  }
  editorState.apply(transaction);
  return true;
};

bool _hasTwoConsecutiveDashes(String text, int end) {
  if (text.length < 2 || end > text.length) {
    return false;
  }
  return text[end - 1] == '-' && text[end - 2] == '-';
}

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
