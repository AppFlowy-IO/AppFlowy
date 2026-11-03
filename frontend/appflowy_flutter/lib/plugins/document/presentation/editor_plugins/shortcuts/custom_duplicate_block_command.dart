import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Duplicate block(s).
///
/// - support
///   - desktop
///   - web
final CommandShortcutEvent customDuplicateBlockCommand = CommandShortcutEvent(
  key: 'duplicate selected block',
  getDescription: () => LocaleKeys.document_plugins_optionAction_duplicate.tr(),
  command: 'ctrl+d',
  macOSCommand: 'cmd+d',
  handler: _duplicateBlockCommandHandler,
);

CommandShortcutEventHandler _duplicateBlockCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  final transaction = editorState.transaction;
  final normalizedSelection = selection.normalized;
  final isMultiBlockSelection =
      normalizedSelection.start.path != normalizedSelection.end.path;

  if (editorState.selectionType == SelectionType.block ||
      isMultiBlockSelection) {
    final nodes = editorState.getNodesInSelection(normalizedSelection);
    if (nodes.isEmpty) {
      return KeyEventResult.ignored;
    }

    transaction.insertNodes(
      normalizedSelection.end.path.next,
      nodes.map((node) => node.deepCopy()).toList(),
    );
  } else {
    final node = editorState.getNodeAtPath(normalizedSelection.end.path);
    if (node == null) {
      return KeyEventResult.ignored;
    }

    transaction.insertNode(node.path.next, node.deepCopy());
  }

  unawaited(
    editorState.apply(transaction).then((_) {
      EditorNotification.paste().post();
    }),
  );

  return KeyEventResult.handled;
};
