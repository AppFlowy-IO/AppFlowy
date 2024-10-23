import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/clipboard_state.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:provider/provider.dart';

/// cut.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CommandShortcutEvent customCutCommand = CommandShortcutEvent(
  key: 'cut the selected content',
  getDescription: () => AppFlowyEditorL10n.current.cmdCutSelection,
  command: 'ctrl+x',
  macOSCommand: 'cmd+x',
  handler: _cutCommandHandler,
);

CommandShortcutEventHandler _cutCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  final context = editorState.document.root.context;
  if (context == null || !context.mounted) {
    return KeyEventResult.ignored;
  }

  context.read<ClipboardState>().didCut();

  handleCopyCommand(editorState, isCut: true);

  if (!selection.isCollapsed) {
    editorState.deleteSelectionIfNeeded();
  } else {
    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) {
      return KeyEventResult.handled;
    }
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    final nextNode = node.next;
    if (nextNode != null && nextNode.delta != null) {
      transaction.afterSelection = Selection.collapsed(
        Position(path: node.path, offset: nextNode.delta?.length ?? 0),
      );
    }
    editorState.apply(transaction);
  }

  return KeyEventResult.handled;
};
