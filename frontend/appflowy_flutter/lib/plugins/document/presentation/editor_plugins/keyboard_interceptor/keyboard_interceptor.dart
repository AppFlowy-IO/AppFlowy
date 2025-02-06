import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_command_extension.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

class EditorKeyboardInterceptor extends AppFlowyKeyboardServiceInterceptor {
  @override
  Future<bool> interceptInsert(
    TextEditingDeltaInsertion insertion,
    EditorState editorState,
    List<CharacterShortcutEvent> characterShortcutEvents,
  ) async {
    // Only check on the mobile platform: check if the inserted text is a link, if so, try to paste it as a link preview
    final text = insertion.textInserted;
    if (UniversalPlatform.isMobile && hrefRegex.hasMatch(text)) {
      final result = customPasteCommand.execute(editorState);
      return result == KeyEventResult.handled;
    }
    return false;
  }

  @override
  Future<bool> interceptReplace(
    TextEditingDeltaReplacement replacement,
    EditorState editorState,
    List<CharacterShortcutEvent> characterShortcutEvents,
  ) async {
    // Only check on the mobile platform: check if the replaced text is a link, if so, try to paste it as a link preview
    final text = replacement.replacementText;
    if (UniversalPlatform.isMobile && hrefRegex.hasMatch(text)) {
      final result = customPasteCommand.execute(editorState);
      return result == KeyEventResult.handled;
    }
    return false;
  }

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

  @override
  Future<bool> interceptDelete(
    TextEditingDeltaDeletion deletion,
    EditorState editorState,
  ) async {
    // check if the current selection is in a code block
    final (isInTableCell, selection, tableCellNode, node) =
        editorState.isCurrentSelectionInTableCell();
    if (!isInTableCell ||
        selection == null ||
        tableCellNode == null ||
        node == null) {
      return false;
    }

    final onlyContainsOneChild = tableCellNode.children.length == 1;
    final isParagraphNode =
        tableCellNode.children.first.type == ParagraphBlockKeys.type;
    if (onlyContainsOneChild &&
        selection.isCollapsed &&
        selection.end.offset == 0 &&
        isParagraphNode) {
      return true;
    }

    return false;
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
