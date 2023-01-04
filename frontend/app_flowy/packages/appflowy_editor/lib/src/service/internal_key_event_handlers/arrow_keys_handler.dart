import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/node_extensions.dart';
import 'package:flutter/material.dart';

ShortcutEventHandler cursorLeftSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  final end = selection.end.goLeft(editorState);
  if (end == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorRightSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  final end = selection.end.goRight(editorState);
  if (end == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorUpSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  final end = _goUp(editorState);
  if (end == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorDownSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  final end = _goDown(editorState);
  if (end == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorTop = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  if (nodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  final position = editorState.document.root.children
      .whereType<TextNode>()
      .first
      .selectable
      ?.start();
  if (position == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    Selection.collapsed(position),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorBottom = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  if (nodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  final position = editorState.document.root.children
      .whereType<TextNode>()
      .last
      .selectable
      ?.end();
  if (position == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    Selection.collapsed(position),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorBegin = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  if (nodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  final position = nodes.first.selectable?.start();
  if (position == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    Selection.collapsed(position),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorEnd = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  if (nodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  final position = nodes.first.selectable?.end();
  if (position == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    Selection.collapsed(position),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorTopSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }

  var start = selection.start;
  var end = selection.end;
  final position = editorState.document.root.children
      .whereType<TextNode>()
      .first
      .selectable
      ?.start();
  if (position != null) {
    end = position;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(start: start, end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorBottomSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  var start = selection.start;
  var end = selection.end;
  final position = editorState.document.root.children
      .whereType<TextNode>()
      .last
      .selectable
      ?.end();
  if (position != null) {
    end = position;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(start: start, end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorBeginSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }

  var start = selection.start;
  var end = selection.end;
  final position = nodes.last.selectable?.start();
  if (position != null) {
    end = position;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(start: start, end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorEndSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }

  var start = selection.start;
  var end = selection.end;
  final position = nodes.last.selectable?.end();
  if (position != null) {
    end = position;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(start: start, end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorUp = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection =
      editorState.service.selectionService.currentSelection.value?.normalized;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  final upPosition = _goUp(editorState);
  editorState.updateCursorSelection(
    upPosition == null ? null : Selection.collapsed(upPosition),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorDown = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection =
      editorState.service.selectionService.currentSelection.value?.normalized;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  final downPosition = _goDown(editorState);
  editorState.updateCursorSelection(
    downPosition == null ? null : Selection.collapsed(downPosition),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorLeft = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection =
      editorState.service.selectionService.currentSelection.value?.normalized;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
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
};

ShortcutEventHandler cursorRight = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection =
      editorState.service.selectionService.currentSelection.value?.normalized;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
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
};

ShortcutEventHandler cursorLeftWordSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  final end =
      selection.end.goLeft(editorState, selectionRange: _SelectionRange.word);
  if (end == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(end: end),
  );
  return KeyEventResult.handled;
};

ShortcutEventHandler cursorRightWordSelect = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final selection = editorState.service.selectionService.currentSelection.value;
  if (nodes.isEmpty || selection == null) {
    return KeyEventResult.ignored;
  }
  final end =
      selection.end.goRight(editorState, selectionRange: _SelectionRange.word);
  if (end == null) {
    return KeyEventResult.ignored;
  }
  editorState.service.selectionService.updateSelection(
    selection.copyWith(end: end),
  );
  return KeyEventResult.handled;
};

enum _SelectionRange {
  character,
  word,
}

extension on Position {
  Position? goLeft(
    EditorState editorState, {
    _SelectionRange selectionRange = _SelectionRange.character,
  }) {
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
    switch (selectionRange) {
      case _SelectionRange.character:
        if (node is TextNode) {
          return Position(
            path: path,
            offset: node.delta.prevRunePosition(offset),
          );
        } else {
          return Position(path: path, offset: offset);
        }
      case _SelectionRange.word:
        if (node is TextNode) {
          final result = node.selectable?.getWordBoundaryInPosition(
            Position(
              path: path,
              offset: node.delta.prevRunePosition(offset),
            ),
          );
          if (result != null) {
            return result.start;
          }
        } else {
          return Position(path: path, offset: offset);
        }
    }
    return null;
  }

  Position? goRight(
    EditorState editorState, {
    _SelectionRange selectionRange = _SelectionRange.character,
  }) {
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
    switch (selectionRange) {
      case _SelectionRange.character:
        if (node is TextNode) {
          return Position(
              path: path, offset: node.delta.nextRunePosition(offset));
        } else {
          return Position(path: path, offset: offset);
        }
      case _SelectionRange.word:
        if (node is TextNode) {
          final result = node.selectable?.getWordBoundaryInPosition(
            Position(
              path: path,
              offset: node.delta.nextRunePosition(offset),
            ),
          );
          if (result != null) {
            return result.end;
          }
        } else {
          return Position(path: path, offset: offset);
        }
    }
    return null;
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
