import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

ShortcutEvent underscoreToItalic = ShortcutEvent(
  key: 'Underscore to italic',
  command: 'shift+underscore',
  handler: _underscoreToItalicHandler,
);

ShortcutEventHandler _underscoreToItalicHandler = (editorState, event) {
  // Obtain the selection and selected nodes of the current document through the 'selectionService'
  // to determine whether the selection is collapsed and whether the selected node is a text node.
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final text = textNode.toRawString();
  // Determine if an 'underscore' already exists in the text node and only once.
  final firstUnderscore = text.indexOf('_');
  final lastUnderscore = text.lastIndexOf('_');
  if (firstUnderscore == -1 ||
      firstUnderscore != lastUnderscore ||
      firstUnderscore == selection.start.offset - 1) {
    return KeyEventResult.ignored;
  }

  // Delete the previous 'underscore',
  // update the style of the text surrounded by the two underscores to 'italic',
  // and update the cursor position.
  TransactionBuilder(editorState)
    ..deleteText(textNode, firstUnderscore, 1)
    ..formatText(
      textNode,
      firstUnderscore,
      selection.end.offset - firstUnderscore - 1,
      {
        BuiltInAttributeKey.italic: true,
      },
    )
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: selection.end.offset - 1,
      ),
    )
    ..commit();

  return KeyEventResult.handled;
};
