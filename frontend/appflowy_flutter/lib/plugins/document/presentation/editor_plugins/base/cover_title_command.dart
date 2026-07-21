import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Press the backspace at the first position of first line to go to the title
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent backspaceToTitle = CommandShortcutEvent(
  key: 'backspace to title',
  command: 'backspace',
  getDescription: () => 'backspace to title',
  handler: (editorState) => _backspaceToTitle(
    editorState: editorState,
  ),
);

KeyEventResult _backspaceToTitle({
  required EditorState editorState,
}) {
  final coverTitleFocusNode = editorState.document.root.context
      ?.read<SharedEditorContext?>()
      ?.coverTitleFocusNode;
  if (coverTitleFocusNode == null) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.selection;
  // only active when the backspace is at the first position of first line
  if (selection == null ||
      !selection.isCollapsed ||
      !selection.start.path.equals([0]) ||
      selection.start.offset != 0) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.type != ParagraphBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  // delete the first line
  () async {
    // only delete the first line if it is empty
    if (node.delta == null || node.delta!.isEmpty) {
      final transaction = editorState.transaction;
      transaction.deleteNode(node);
      transaction.afterSelection = null;
      await editorState.apply(transaction);
    }

    editorState.selection = null;
    coverTitleFocusNode.requestFocus();
  }();

  return KeyEventResult.handled;
}

/// Press the arrow left at the first position of first line to go to the title
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent arrowLeftToTitle = CommandShortcutEvent(
  key: 'arrow left to title',
  command: 'arrow left',
  getDescription: () => 'arrow left to title',
  handler: (editorState) => _arrowKeyToTitle(
    editorState: editorState,
    checkSelection: (selection) {
      if (!selection.isCollapsed ||
          !selection.start.path.equals([0]) ||
          selection.start.offset != 0) {
        return false;
      }
      return true;
    },
  ),
);

/// Press the arrow up at the first line to go to the title
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent arrowUpToTitle = CommandShortcutEvent(
  key: 'arrow up to title',
  command: 'arrow up',
  getDescription: () => 'arrow up to title',
  handler: (editorState) => _arrowKeyToTitle(
    editorState: editorState,
    // Only jump to the title from the first VISUAL line of the first
    // block. Without this, when the first block wraps onto several lines,
    // arrow-up from any lower line skips the block's own upper lines and
    // goes straight to the title.
    onlyFromFirstVisualLine: true,
    checkSelection: (selection) {
      if (!selection.isCollapsed || !selection.start.path.equals([0])) {
        return false;
      }
      return true;
    },
  ),
);

KeyEventResult _arrowKeyToTitle({
  required EditorState editorState,
  required bool Function(Selection selection) checkSelection,

  /// When true, only jump to the title if the caret is on the block's first
  /// visual (soft-wrapped) line. Best-effort: if the caret geometry can't be
  /// resolved (see [_isOnFirstVisualLine]), the jump is allowed anyway so
  /// the key is never swallowed.
  bool onlyFromFirstVisualLine = false,
}) {
  final coverTitleFocusNode = editorState.document.root.context
      ?.read<SharedEditorContext?>()
      ?.coverTitleFocusNode;
  if (coverTitleFocusNode == null) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.selection;
  // only active when the arrow up is at the first line
  if (selection == null || !checkSelection(selection)) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null) {
    return KeyEventResult.ignored;
  }

  // When the first block wraps, arrow-up should walk up the block's own
  // visual lines before reaching the title. Only the first visual line has
  // nothing above it inside the block.
  if (onlyFromFirstVisualLine && !_isOnFirstVisualLine(node, selection.end)) {
    return KeyEventResult.ignored;
  }

  editorState.selection = null;
  coverTitleFocusNode.requestFocus();

  return KeyEventResult.handled;
}

/// Whether [position] renders on the first visual (soft-wrapped) line of
/// [node].
///
/// [Position] has no notion of visual lines, so this compares the caret
/// rect at [position] against the caret rect at the block's start: a lower
/// visual line sits about a line-height below the first. If the geometry
/// can't be resolved, it returns `true` so the caller keeps the previous
/// "first block" behavior rather than swallowing the key.
bool _isOnFirstVisualLine(Node node, Position position) {
  final selectable = node.selectable;
  if (selectable == null) {
    return true;
  }
  final caret = selectable.getCursorRectInPosition(position);
  final firstLineCaret = selectable.getCursorRectInPosition(
    Position(path: node.path, offset: 0),
  );
  if (caret == null || firstLineCaret == null) {
    return true;
  }
  // Carets on the same visual line share (almost) the same top; a caret on a
  // lower line sits at least one line-height further down. Half the first
  // line's height is a midpoint between those two cases, tolerating small
  // rounding differences without misreading the second line as the first.
  // The first line's height is the basis so the check is robust to later
  // lines having different heights (e.g. differing font sizes).
  return caret.top <= firstLineCaret.top + firstLineCaret.height / 2;
}
