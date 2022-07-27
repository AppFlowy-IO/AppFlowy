import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

int _endOffsetOfNode(Node node) {
  if (node is TextNode) {
    return node.delta.length;
  }
  return 0;
}

FlowyKeyEventHandler arrowKeysHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.arrowUp &&
      event.logicalKey != LogicalKeyboardKey.arrowDown &&
      event.logicalKey != LogicalKeyboardKey.arrowLeft &&
      event.logicalKey != LogicalKeyboardKey.arrowRight) {
    return KeyEventResult.ignored;
  }

  final currentSelection = editorState.cursorSelection;
  if (currentSelection == null) {
    return KeyEventResult.ignored;
  }

  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    // turn left
    if (currentSelection.isCollapsed) {
      final end = currentSelection.end;
      final offset = end.offset;
      if (offset == 0) {
        final node = editorState.document.nodeAtPath(end.path)!;
        final prevNode = node.previous;
        if (prevNode != null) {
          editorState.updateCursorSelection(Selection.collapsed(Position(
              path: prevNode.path, offset: _endOffsetOfNode(prevNode))));
        }
        return KeyEventResult.handled;
      }
      editorState.updateCursorSelection(
          Selection.collapsed(Position(path: end.path, offset: offset - 1)));
    } else {
      editorState
          .updateCursorSelection(currentSelection.collapse(atStart: true));
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    if (currentSelection.isCollapsed) {
      final end = currentSelection.end;
      final offset = end.offset;
      final node = editorState.document.nodeAtPath(end.path)!;
      final lengthOfNode = _endOffsetOfNode(node);
      if (offset >= lengthOfNode) {
        final nextNode = node.next;
        if (nextNode != null) {
          editorState.updateCursorSelection(
              Selection.collapsed(Position(path: nextNode.path, offset: 0)));
        }
        return KeyEventResult.handled;
      }

      editorState.updateCursorSelection(
          Selection.collapsed(Position(path: end.path, offset: offset + 1)));
    } else {
      editorState.updateCursorSelection(currentSelection.collapse());
    }
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
};
