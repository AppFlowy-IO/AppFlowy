import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';

ShortcutEvent enterInTableCell = ShortcutEvent(
  key: 'Don\'t add new line in table cell',
  command: 'enter',
  handler: _enterInTableCell,
);

ShortcutEventHandler _enterInTableCell = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final inTableNodes = nodes
      .whereType<TextNode>()
      .where((node) => node.parent?.id.contains(kTableType) ?? false);
  if (inTableNodes.isNotEmpty) {
    // TODO(zoli): move cursor to next cell, if on last cell create new line after
    //if (inTableNodes.length == 1) {}
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
