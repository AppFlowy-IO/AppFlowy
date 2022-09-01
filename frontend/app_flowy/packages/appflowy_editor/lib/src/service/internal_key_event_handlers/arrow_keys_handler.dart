import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/node_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

AppFlowyKeyEventHandler arrowKeysHandler = (editorState, event) {
  if (!_arrowKeys.contains(event.logicalKey)) {
    return KeyEventResult.ignored;
  }

  if (event.isMetaPressed && event.isShiftPressed) {
    return _arrowKeysWithMetaAndShift(editorState, event);
  } else if (event.isMetaPressed) {
    return _arrowKeysWithMeta(editorState, event);
  } else if (event.isShiftPressed) {
    return _arrowKeysWithShift(editorState, event);
  } else {
    return _arrowKeysOnly(editorState, event);
  }
};

final _arrowKeys = [
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown
];

KeyEventResult _arrowKeysWithMetaAndShift(
    EditorState editorState, RawKeyEvent event) {
  if (!event.isMetaPressed ||
      !event.isShiftPressed ||
      !_arrowKeys.contains(event.logicalKey)) {
    assert(false);
    return KeyEventResult.ignored;
  }

  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }

  var start = selection.start;
  var end = selection.end;
  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    final position = nodes.first.selectable?.start();
    if (position != null) {
      end = position;
    }
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    final position = nodes.first.selectable?.end();
    if (position != null) {
      end = position;
    }
  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    final position = editorState.document.root.children
        .whereType<TextNode>()
        .first
        .selectable
        ?.start();
    if (position != null) {
      end = position;
    }
  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    final position = editorState.document.root.children
        .whereType<TextNode>()
        .last
        .selectable
        ?.end();
    if (position != null) {
      end = position;
    }
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(start: start, end: end),
  );
  return KeyEventResult.handled;
}

// Move the cursor to top, bottom, left and right of the document.
KeyEventResult _arrowKeysWithMeta(EditorState editorState, RawKeyEvent event) {
  if (!event.isMetaPressed ||
      event.isShiftPressed ||
      !_arrowKeys.contains(event.logicalKey)) {
    assert(false);
    return KeyEventResult.ignored;
  }

  final nodes = editorState.service.selectionService.currentSelectedNodes;
  if (nodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  Position? position;
  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    position = nodes.first.selectable?.start();
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    position = nodes.last.selectable?.end();
  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    position = editorState.document.root.children
        .whereType<TextNode>()
        .first
        .selectable
        ?.start();
  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    position = editorState.document.root.children
        .whereType<TextNode>()
        .last
        .selectable
        ?.end();
  }
  if (position == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    Selection.collapsed(position),
  );
  return KeyEventResult.handled;
}

KeyEventResult _arrowKeysWithShift(EditorState editorState, RawKeyEvent event) {
  if (event.isMetaPressed ||
      !event.isShiftPressed ||
      !_arrowKeys.contains(event.logicalKey)) {
    assert(false);
    return KeyEventResult.ignored;
  }

  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  Position? end;
  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    end = selection.end.goLeft(editorState);
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    end = selection.end.goRight(editorState);
  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    end = _goUp(editorState);
  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    end = _goDown(editorState);
  }
  if (end == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService
      .updateSelection(selection.copyWith(end: end));
  return KeyEventResult.handled;
}

KeyEventResult _arrowKeysOnly(EditorState editorState, RawKeyEvent event) {
  if (event.isMetaPressed ||
      event.isShiftPressed ||
      !_arrowKeys.contains(event.logicalKey)) {
    assert(false);
    return KeyEventResult.ignored;
  }

  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection =
      editorState.service.selectionService.currentSelection.value?.normalize;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
    if (selection.isCollapsed) {
      final leftPosition = selection.start.goLeft(editorState);
      if (leftPosition != null) {
        editorState.service.selectionService.updateSelection(
          Selection.collapsed(leftPosition),
        );
      }
    } else {
      editorState.service.selectionService.updateSelection(
        Selection.collapsed(selection.start),
      );
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
    if (selection.isCollapsed) {
      final rightPosition = selection.start.goRight(editorState);
      if (rightPosition != null) {
        editorState.service.selectionService.updateSelection(
          Selection.collapsed(rightPosition),
        );
      }
    } else {
      editorState.service.selectionService.updateSelection(
        Selection.collapsed(selection.end),
      );
    }
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    final upPosition = _goUp(editorState);
    editorState.updateCursorSelection(
      upPosition == null ? null : Selection.collapsed(upPosition),
    );
    return KeyEventResult.handled;
  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    final downPosition = _goDown(editorState);
    editorState.updateCursorSelection(
      downPosition == null ? null : Selection.collapsed(downPosition),
    );
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

extension on Position {
  Position? goLeft(EditorState editorState) {
    final node = editorState.document.nodeAtPath(path);
    if (node == null) {
      return null;
    }
    if (offset == 0) {
      final previousEnd = node.previous?.selectable?.end();
      if (previousEnd != null) {
        return previousEnd;
      }
      return null;
    }
    if (node is TextNode) {
      return Position(path: path, offset: node.delta.prevRunePosition(offset));
    } else {
      return Position(path: path, offset: offset);
    }
  }

  Position? goRight(EditorState editorState) {
    final node = editorState.document.nodeAtPath(path);
    if (node == null) {
      return null;
    }
    final end = node.selectable?.end();
    if (end != null && offset >= end.offset) {
      final nextStart = node.next?.selectable?.start();
      if (nextStart != null) {
        return nextStart;
      }
      return null;
    }
    if (node is TextNode) {
      return Position(path: path, offset: node.delta.nextRunePosition(offset));
    } else {
      return Position(path: path, offset: offset);
    }
  }
}

Position? _goUp(EditorState editorState) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final rects = editorState.service.selectionService.selectionRects;
  if (rects.isEmpty || selection == null) {
    return null;
  }
  Offset offset;
  if (selection.isBackward) {
    final rect = rects.reduce(
      (current, next) => current.bottom >= next.bottom ? current : next,
    );
    offset = rect.topRight.translate(0, -rect.height);
  } else {
    final rect = rects.reduce(
      (current, next) => current.top <= next.top ? current : next,
    );
    offset = rect.topLeft.translate(0, -rect.height);
  }
  return editorState.service.selectionService.getPositionInOffset(offset);
}

Position? _goDown(EditorState editorState) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final rects = editorState.service.selectionService.selectionRects;
  if (rects.isEmpty || selection == null) {
    return null;
  }
  Offset offset;
  if (selection.isBackward) {
    final rect = rects.reduce(
      (current, next) => current.bottom >= next.bottom ? current : next,
    );
    offset = rect.bottomRight.translate(0, rect.height);
  } else {
    final rect = rects.reduce(
      (current, next) => current.top <= next.top ? current : next,
    );
    offset = rect.bottomLeft.translate(0, rect.height);
  }
  return editorState.service.selectionService.getPositionInOffset(offset);
}
