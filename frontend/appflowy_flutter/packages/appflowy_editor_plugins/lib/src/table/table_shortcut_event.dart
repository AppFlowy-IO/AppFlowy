import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';

ShortcutEvent backSpaceInTableCell = ShortcutEvent(
  key: 'Don\'t move cell text outside',
  command: 'backspace',
  handler: _backSpaceInTableCell,
);

ShortcutEvent enterInTableCell = ShortcutEvent(
  key: 'Don\'t add new line in table cell',
  command: 'enter',
  handler: _enterInTableCell,
);

ShortcutEventHandler _backSpaceInTableCell = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  var selection = editorState.service.selectionService.currentSelection.value;
  final inTableNodes = nodes.whereType<TextNode>().where((node) =>
      node.parent != null ? node.parent!.id.contains(kTableType) : false);
  print(inTableNodes.length);
  for (var node in inTableNodes) {
    print('${node.id}, ${node.path}');
  }
  return KeyEventResult.handled;
};

ShortcutEventHandler _enterInTableCell = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final inTableNodes = nodes.whereType<TextNode>().where((node) =>
      node.parent != null ? node.parent!.id.contains(kTableType) : false);
  if (inTableNodes.isNotEmpty) {
    // TODO(zoli): move selection to next cell
    //if (inTableNodes.length == 1) {}
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
