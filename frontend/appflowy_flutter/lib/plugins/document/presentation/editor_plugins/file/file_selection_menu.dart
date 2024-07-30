import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

final fileMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_plugins_file_name.tr(),
  icon: (_, isSelected, style) => SelectionMenuIconWidget(
    icon: Icons.file_present_outlined,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['file', 'pdf', 'zip', 'archive', 'upload'],
  handler: (editorState, _, __) async => editorState.insertEmptyFileBlock(),
);

extension InsertFile on EditorState {
  Future<void> insertEmptyFileBlock() async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final file = fileNode(url: '');
    final transaction = this.transaction;

    // if the current node is empty paragraph, replace it with the file node
    if (node.type == ParagraphBlockKeys.type &&
        (node.delta?.isEmpty ?? false)) {
      transaction
        ..insertNode(node.path, file)
        ..deleteNode(node);
    } else {
      transaction.insertNode(node.path.next, file);
    }

    transaction.afterSelection =
        Selection.collapsed(Position(path: node.path.next));

    return apply(transaction);
  }
}
