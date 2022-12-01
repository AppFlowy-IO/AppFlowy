import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/code_block/code_block_node_widget.dart';
import 'package:flutter/material.dart';

ShortcutEvent enterInCodeBlock = ShortcutEvent(
  key: 'Press Enter In Code Block',
  command: 'enter',
  handler: _enterInCodeBlockHandler,
);

ShortcutEvent ignoreKeysInCodeBlock = ShortcutEvent(
  key: 'White space in code block',
  command: 'space, slash, shift+underscore',
  handler: _ignorekHandler,
);

ShortcutEventHandler _enterInCodeBlockHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final codeBlockNode =
      nodes.whereType<TextNode>().where((node) => node.id == kCodeBlockType);
  if (codeBlockNode.length != 1 ||
      selection == null ||
      !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  final transaction = editorState.transaction
    ..insertText(
      codeBlockNode.first,
      selection.end.offset,
      '\n',
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
};

ShortcutEventHandler _ignorekHandler = (editorState, event) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final codeBlockNodes =
      nodes.whereType<TextNode>().where((node) => node.id == kCodeBlockType);
  if (codeBlockNodes.length == 1) {
    return KeyEventResult.skipRemainingHandlers;
  }
  return KeyEventResult.ignored;
};

SelectionMenuItem codeBlockMenuItem = SelectionMenuItem(
  name: () => 'Code Block',
  icon: (editorState, onSelected) => Icon(
    Icons.abc,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    size: 18.0,
  ),
  keywords: ['code block', 'code snippet'],
  handler: (editorState, _, __) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (selection == null || textNodes.isEmpty) {
      return;
    }
    final transaction = editorState.transaction;
    if (textNodes.first.toPlainText().isEmpty) {
      transaction.updateNode(textNodes.first, {
        BuiltInAttributeKey.subtype: kCodeBlockSubType,
        kCodeBlockAttrTheme: 'vs',
        kCodeBlockAttrLanguage: null,
      });
      transaction.afterSelection = selection;
      editorState.apply(transaction);
    } else {
      transaction.insertNode(
        selection.end.path,
        TextNode(
          attributes: {
            BuiltInAttributeKey.subtype: kCodeBlockSubType,
            kCodeBlockAttrTheme: 'vs',
            kCodeBlockAttrLanguage: null,
          },
          delta: Delta()..insert('\n'),
        ),
      );
      transaction.afterSelection = selection;
    }
    editorState.apply(transaction);
  },
);
