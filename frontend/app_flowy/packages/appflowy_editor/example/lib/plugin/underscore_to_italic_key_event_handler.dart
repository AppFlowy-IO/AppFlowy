import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

AppFlowyKeyEventHandler underscoreToItalicHandler = (editorState, event) {
  // Since we only need to handler the input of `underscore`.
  // All inputs except `underscore` will be ignored directly.
  if (event.logicalKey != LogicalKeyboardKey.underscore) {
    return KeyEventResult.ignored;
  }

  // Obtaining the selection and selected nodes of the current document through `selectionService`,
  // and determine whether it is a single selection and whether the selected node is a text node.
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final text = textNode.toRawString();
  // Determine if `underscore` already exists in the text node
  final previousUnderscore = text.indexOf('_');
  if (previousUnderscore == -1) {
    return KeyEventResult.ignored;
  }

  // Delete the previous `underscore`,
  // update the style of the text surrounded by two underscores to `italic`,
  // and update the cursor position.
  TransactionBuilder(editorState)
    ..deleteText(textNode, previousUnderscore, 1)
    ..formatText(
      textNode,
      previousUnderscore,
      selection.end.offset - previousUnderscore - 1,
      {'italic': true},
    )
    ..afterSelection = Selection.collapsed(
      Position(path: textNode.path, offset: selection.end.offset - 1),
    )
    ..commit();

  return KeyEventResult.handled;
};
