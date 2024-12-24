import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'slash_menu_item_builder.dart';

final _keywords = [
  'outline',
  'table of contents',
  'toc',
  'tableofcontents',
];

/// Outline menu item
SelectionMenuItem outlineSlashMenuItem = SelectionMenuItem(
  getName: LocaleKeys.document_selectionMenu_outline.tr,
  keywords: _keywords,
  handler: (editorState, _, __) async => editorState.insertOutline(),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, onSelected, style) {
    return Icon(
      Icons.list_alt,
      color: onSelected
          ? style.selectionMenuItemSelectedIconColor
          : style.selectionMenuItemIconColor,
      size: 16.0,
    );
  },
);

extension on EditorState {
  Future<void> insertOutline() async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final node = getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    final transaction = this.transaction;
    final bReplace = node.delta?.isEmpty ?? false;

    //default insert after
    var path = node.path.next;
    if (bReplace) {
      path = node.path;
    }

    final nextNode = getNodeAtPath(path.next);

    transaction
      ..insertNodes(
        path,
        [
          outlineBlockNode(),
          if (nextNode == null || nextNode.delta == null) paragraphNode(),
        ],
      )
      ..afterSelection = Selection.collapsed(
        Position(path: path.next),
      );

    if (bReplace) {
      transaction.deleteNode(node);
    }

    await apply(transaction);
  }
}
