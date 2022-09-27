import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/path_extensions.dart';
import 'package:flutter/material.dart';

// convert **abc** to bold abc.
ShortcutEventHandler doubleAsterisksToBold = (editorState, event) {
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final text = textNode.toRawString().substring(0, selection.end.offset);

  // make sure the last two characters are **.
  if (text.length < 2 || text[selection.end.offset - 1] != '*') {
    return KeyEventResult.ignored;
  }

  // find all the index of `*`.
  final asteriskIndexes = <int>[];
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '*') {
      asteriskIndexes.add(i);
    }
  }

  if (asteriskIndexes.length < 3) {
    return KeyEventResult.ignored;
  }

  // make sure the second to last and third to last asterisks are connected.
  final thirdToLastAsteriskIndex = asteriskIndexes[asteriskIndexes.length - 3];
  final secondToLastAsteriskIndex = asteriskIndexes[asteriskIndexes.length - 2];
  final lastAsterisIndex = asteriskIndexes[asteriskIndexes.length - 1];
  if (secondToLastAsteriskIndex != thirdToLastAsteriskIndex + 1 ||
      lastAsterisIndex == secondToLastAsteriskIndex + 1) {
    return KeyEventResult.ignored;
  }

  // delete the last three asterisks.
  // update the style of the text surround by `** **` to bold.
  // and update the cursor position.
  TransactionBuilder(editorState)
    ..deleteText(textNode, lastAsterisIndex, 1)
    ..deleteText(textNode, thirdToLastAsteriskIndex, 2)
    ..formatText(
      textNode,
      thirdToLastAsteriskIndex,
      selection.end.offset - thirdToLastAsteriskIndex - 3,
      {
        BuiltInAttributeKey.bold: true,
        BuiltInAttributeKey.defaultFormating: true,
      },
    )
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: selection.end.offset - 3,
      ),
    )
    ..commit();

  return KeyEventResult.handled;
};

// convert __abc__ to bold abc.
ShortcutEventHandler doubleUnderscoresToBold = (editorState, event) {
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final text = textNode.toRawString().substring(0, selection.end.offset);

  // make sure the last two characters are __.
  if (text.length < 2 || text[selection.end.offset - 1] != '_') {
    return KeyEventResult.ignored;
  }

  // find all the index of `_`.
  final underscoreIndexes = <int>[];
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '_') {
      underscoreIndexes.add(i);
    }
  }

  if (underscoreIndexes.length < 3) {
    return KeyEventResult.ignored;
  }

  // make sure the second to last and third to last underscores are connected.
  final thirdToLastUnderscoreIndex =
      underscoreIndexes[underscoreIndexes.length - 3];
  final secondToLastUnderscoreIndex =
      underscoreIndexes[underscoreIndexes.length - 2];
  final lastAsterisIndex = underscoreIndexes[underscoreIndexes.length - 1];
  if (secondToLastUnderscoreIndex != thirdToLastUnderscoreIndex + 1 ||
      lastAsterisIndex == secondToLastUnderscoreIndex + 1) {
    return KeyEventResult.ignored;
  }

  // delete the last three underscores.
  // update the style of the text surround by `__ __` to bold.
  // and update the cursor position.
  TransactionBuilder(editorState)
    ..deleteText(textNode, lastAsterisIndex, 1)
    ..deleteText(textNode, thirdToLastUnderscoreIndex, 2)
    ..formatText(
      textNode,
      thirdToLastUnderscoreIndex,
      selection.end.offset - thirdToLastUnderscoreIndex - 3,
      {
        BuiltInAttributeKey.bold: true,
        BuiltInAttributeKey.defaultFormating: true,
      },
    )
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: selection.end.offset - 3,
      ),
    )
    ..commit();

  return KeyEventResult.handled;
};
