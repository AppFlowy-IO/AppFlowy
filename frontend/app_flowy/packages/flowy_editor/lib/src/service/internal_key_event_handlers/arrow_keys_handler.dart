import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/src/service/keyboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

int _endOffsetOfNode(Node node) {
  if (node is TextNode) {
    return node.delta.length;
  }
  return 0;
}

extension on Position {
  Position? goLeft(EditorState editorState) {
    if (offset == 0) {
      final node = editorState.document.nodeAtPath(path)!;
      final prevNode = node.previous;
      if (prevNode != null) {
        return Position(
            path: prevNode.path, offset: _endOffsetOfNode(prevNode));
      }
      return null;
    }

    return Position(path: path, offset: offset - 1);
  }

  Position? goRight(EditorState editorState) {
    final node = editorState.document.nodeAtPath(path)!;
    final lengthOfNode = _endOffsetOfNode(node);
    if (offset >= lengthOfNode) {
      final nextNode = node.next;
      if (nextNode != null) {
        return Position(path: nextNode.path, offset: 0);
      }
      return null;
    }

    return Position(path: path, offset: offset + 1);
  }
}

Position? _goUp(EditorState editorState) {
  final rects = editorState.service.selectionService.rects();
  if (rects.isEmpty) {
    return null;
  }
  final first = rects.first;
  final firstOffset = Offset(first.left, first.top);
  final hitOffset = firstOffset - Offset(0, first.height * 0.5);
  return editorState.service.selectionService.hitTest(hitOffset);
}

Position? _goDown(EditorState editorState) {
  final rects = editorState.service.selectionService.rects();
  if (rects.isEmpty) {
    return null;
  }
  final first = rects.last;
  final firstOffset = Offset(first.right, first.bottom);
  final hitOffset = firstOffset + Offset(0, first.height * 0.5);
  return editorState.service.selectionService.hitTest(hitOffset);
}

KeyEventResult _handleShiftKey(EditorState editorState, RawKeyEvent event) {
  final currentSelection = editorState.cursorSelection;
  if (currentSelection == null) {
    return KeyEventResult.ignored;
  }

  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    final leftPosition = currentSelection.end.goLeft(editorState);
    editorState.updateCursorSelection(leftPosition == null
        ? null
        : Selection(start: currentSelection.start, end: leftPosition));
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    final rightPosition = currentSelection.start.goRight(editorState);
    editorState.updateCursorSelection(rightPosition == null
        ? null
        : Selection(start: rightPosition, end: currentSelection.end));
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    final position = _goUp(editorState);
    editorState.updateCursorSelection(position == null
        ? null
        : Selection(start: position, end: currentSelection.end));
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    final position = _goDown(editorState);
    editorState.updateCursorSelection(position == null
        ? null
        : Selection(start: currentSelection.start, end: position));
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
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
      final leftPosition = currentSelection.start.goLeft(editorState);
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
      final rightPosition = currentSelection.end.goRight(editorState);
      if (rightPosition != null) {
        editorState.updateCursorSelection(Selection.collapsed(rightPosition));
      }
    } else {
      editorState.updateCursorSelection(currentSelection.collapse());
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    final position = _goUp(editorState);
    editorState.updateCursorSelection(
        position == null ? null : Selection.collapsed(position));
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    final position = _goDown(editorState);
    editorState.updateCursorSelection(
        position == null ? null : Selection.collapsed(position));
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
};
