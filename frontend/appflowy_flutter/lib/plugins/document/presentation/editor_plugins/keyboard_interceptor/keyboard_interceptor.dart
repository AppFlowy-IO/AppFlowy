import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/services.dart';

class EditorKeyboardInterceptor extends AppFlowyKeyboardServiceInterceptor {
  @override
  Future<bool> interceptNonTextUpdate(
    TextEditingDeltaNonTextUpdate nonTextUpdate,
    EditorState editorState,
    List<CharacterShortcutEvent> characterShortcutEvents,
  ) async {
    return _checkIfBacktickPressed(
      editorState,
      nonTextUpdate,
    );
  }

  /// Check if the backtick pressed event should be handled
  Future<bool> _checkIfBacktickPressed(
    EditorState editorState,
    TextEditingDeltaNonTextUpdate nonTextUpdate,
  ) async {
    // if the composing range is not empty, it means the user is typing a text,
    // so we don't need to handle the backtick pressed event
    if (!nonTextUpdate.composing.isCollapsed ||
        !nonTextUpdate.selection.isCollapsed) {
      return false;
    }

    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      AppFlowyEditorLog.input.debug('selection is null or not collapsed');
      return false;
    }

    final node = editorState.getNodesInSelection(selection).firstOrNull;
    if (node == null) {
      AppFlowyEditorLog.input.debug('node is null');
      return false;
    }

    // get last character of the node
    final plainText = node.delta?.toPlainText();
    // three backticks to code block
    if (plainText != '```') {
      return false;
    }

    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.end.path,
      codeBlockNode(),
    );
    transaction.deleteNode(node);
    transaction.afterSelection = Selection.collapsed(
      Position(path: selection.start.path),
    );
    await editorState.apply(transaction);

    return true;
  }
}
