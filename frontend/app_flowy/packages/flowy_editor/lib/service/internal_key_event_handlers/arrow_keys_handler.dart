import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

int _endOffsetOfNode(Node node) {
  if (node is TextNode) {
    return node.delta.length;
  }
  return 0;
}

KeyEventResult _handleShiftKey(EditorState editorState, RawKeyEvent event) {
  final currentSelection = editorState.cursorSelection;
  if (currentSelection == null) {
    return KeyEventResult.ignored;
  }

  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    final leftPosition = _leftPosition(editorState, currentSelection.start);
    if (leftPosition != null) {
      editorState.updateCursorSelection(
          Selection(start: leftPosition, end: currentSelection.end));
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    final rightPosition = _rightPosition(editorState, currentSelection.end);
    if (rightPosition != null) {
      editorState.updateCursorSelection(
          Selection(start: currentSelection.start, end: rightPosition));
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

Position? _leftPosition(EditorState editorState, Position position) {
  final offset = position.offset;
  if (offset == 0) {
    final node = editorState.document.nodeAtPath(position.path)!;
    final prevNode = node.previous;
    if (prevNode != null) {
      editorState.updateCursorSelection(Selection.collapsed(
          Position(path: prevNode.path, offset: _endOffsetOfNode(prevNode))));
    }
    return null;
  }

  return Position(path: position.path, offset: offset - 1);
}

Position? _rightPosition(EditorState editorState, Position position) {
  final offset = position.offset;
  final node = editorState.document.nodeAtPath(position.path)!;
  final lengthOfNode = _endOffsetOfNode(node);
  if (offset >= lengthOfNode) {
    final nextNode = node.next;
    if (nextNode != null) {
      Position(path: nextNode.path, offset: 0);
    }
    return null;
  }

  return Position(path: position.path, offset: offset + 1);
}

FlowyKeyEventHandler arrowKeysHandler = (editorState, event) {
  if (event.isShiftPressed) {
    return _handleShiftKey(editorState, event);
  }

  final currentSelection = editorState.cursorSelection;
  if (currentSelection == null) {
    return KeyEventResult.ignored;
  }

  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    if (currentSelection.isCollapsed) {
      final leftPosition = _leftPosition(editorState, currentSelection.start);
      if (leftPosition != null) {
        editorState.updateCursorSelection(Selection.collapsed(leftPosition));
      }
    } else {
      editorState
          .updateCursorSelection(currentSelection.collapse(atStart: true));
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    if (currentSelection.isCollapsed) {
      final rightPosition = _rightPosition(editorState, currentSelection.end);
      if (rightPosition != null) {
        editorState.updateCursorSelection(Selection.collapsed(rightPosition));
      }
    } else {
      editorState.updateCursorSelection(currentSelection.collapse());
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    final rects = editorState.service.selectionService.rects();
    if (rects.isEmpty) {
      return KeyEventResult.handled;
    }
    final first = rects.first;
    final firstOffset = Offset(first.left, first.top);
    final hitOffset = firstOffset - Offset(0, first.height * 0.5);
    editorState.service.selectionService.hit(hitOffset);
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    final rects = editorState.service.selectionService.rects();
    if (rects.isEmpty) {
      return KeyEventResult.handled;
    }
    final first = rects.last;
    final firstOffset = Offset(first.right, first.bottom);
    final hitOffset = firstOffset + Offset(0, first.height * 0.5);
    editorState.service.selectionService.hit(hitOffset);
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
};
