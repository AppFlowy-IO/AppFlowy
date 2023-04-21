import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor_plugins/src/divider/dotted_divider_node_widget.dart';

// insert divider into a document by typing three minuses.
// ---

ShortcutEvent insertDottedDividerEvent = ShortcutEvent(
  key: 'DottedDivider',
  command: "shift+underscore",
  windowsCommand: "shift+underscore",
  handler: _insertDottedDividerHandler,
);

ShortcutEventHandler _insertDottedDividerHandler = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final textNodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  if (textNodes.length != 1 || selection == null) {
    return KeyEventResult.ignored;
  }
  final textNode = textNodes.first;
  if (textNode.toPlainText() != '__') {
    return KeyEventResult.ignored;
  }
  final transaction = editorState.transaction
    ..deleteText(textNode, 0, 2) // remove the existing minuses.
    ..insertNode(
        textNode.path, Node(type: kDottedDividerType)) // insert the divder
    ..afterSelection = Selection.single(
      // update selection to the next text node.
      path: textNode.path.next,
      startOffset: 0,
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
};

SelectionMenuItem dottedDividerMenuItem = SelectionMenuItem(
  name: 'DottedDivider',
  icon: (editorState, onSelected) => Icon(
    Icons.horizontal_rule,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    size: 18.0,
  ),
  keywords: ['horizontal dotted rule', 'dotted_divider'],
  handler: (editorState, _, __) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (textNodes.length != 1 || selection == null) {
      return;
    }
    final textNode = textNodes.first;
    // insert the divider at current path if the text node is empty.
    if (textNode.toPlainText().isEmpty) {
      final transaction = editorState.transaction
        ..insertNode(textNode.path, Node(type: kDottedDividerType))
        ..afterSelection = Selection.single(
          path: textNode.path.next,
          startOffset: 0,
        );
      editorState.apply(transaction);
    } else {
      // insert the divider at the path next to current path if the text node is not empty.
      final transaction = editorState.transaction
        ..insertNode(selection.end.path.next, Node(type: kDottedDividerType))
        ..afterSelection = selection;
      editorState.apply(transaction);
    }
  },
);
