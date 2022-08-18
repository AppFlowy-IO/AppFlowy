import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

KeyEventResult _selectAll(EditorState editorState) {
  if (editorState.document.root.children.isEmpty) {
    return KeyEventResult.handled;
  }
  final firstNode = editorState.document.root.children.first;
  final lastNode = editorState.document.root.children.last;
  var offset = 0;
  if (lastNode is TextNode) {
    offset = lastNode.delta.length;
  }
  editorState.updateCursorSelection(Selection(
      start: Position(path: firstNode.path, offset: 0),
      end: Position(path: lastNode.path, offset: offset)));
  return KeyEventResult.handled;
}

AppFlowyKeyEventHandler selectAllHandler = (editorState, event) {
  if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
    return _selectAll(editorState);
  }
  return KeyEventResult.ignored;
};
