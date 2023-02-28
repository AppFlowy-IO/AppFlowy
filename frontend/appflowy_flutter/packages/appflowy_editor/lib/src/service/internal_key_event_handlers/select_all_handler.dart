import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';
import 'package:flutter/material.dart';

ShortcutEventHandler selectAllHandler = (editorState, event) {
  if (editorState.document.root.children.isEmpty) {
    return KeyEventResult.handled;
  }
  final firstNode = editorState.document.root.children.first;
  final lastNode = editorState.document.root.children.last;
  var offset = 0;
  if (lastNode is TextNode) {
    offset = lastNode.delta.length;
  }
  editorState.updateCursorSelection(
    Selection(
      start: Position(path: firstNode.path, offset: 0),
      end: Position(path: lastNode.path, offset: offset),
    ),
  );
  return KeyEventResult.handled;
};
