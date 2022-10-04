import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';
import 'package:flutter/material.dart';

bool _isCodeStyle(TextNode textNode, int index) {
  return textNode.allSatisfyCodeInSelection(Selection.single(
      path: textNode.path, startOffset: index, endOffset: index + 1));
}

// enter escape mode when start two backquote
bool _isEscapeBackquote(String text, List<int> backquoteIndexes) {
  if (backquoteIndexes.length >= 2) {
    final firstBackquoteIndex = backquoteIndexes[0];
    final secondBackquoteIndex = backquoteIndexes[1];
    return firstBackquoteIndex == secondBackquoteIndex - 1;
  }
  return false;
}

// find all the index of `, exclusion in code style.
List<int> _findBackquoteIndexes(String text, TextNode textNode) {
  final backquoteIndexes = <int>[];
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '`' && _isCodeStyle(textNode, i) == false) {
      backquoteIndexes.add(i);
    }
  }
  return backquoteIndexes;
}

/// To denote a word or phrase as code, enclose it in backticks (`).
/// If the word or phrase you want to denote as code includes one or more
/// backticks, you can escape it by enclosing the word or phrase in double
/// backticks (``).
ShortcutEventHandler backquoteToCodeHandler = (editorState, event) {
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();

  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final selectionText = textNode
      .toRawString()
      .substring(selection.start.offset, selection.end.offset);

  // toggle code style when selected some text
  if (selectionText.isNotEmpty) {
    formatEmbedCode(editorState);
    return KeyEventResult.handled;
  }

  final text = textNode.toRawString().substring(0, selection.end.offset);
  final backquoteIndexes = _findBackquoteIndexes(text, textNode);
  if (backquoteIndexes.isEmpty) {
    return KeyEventResult.ignored;
  }

  final endIndex = selection.end.offset;

  if (_isEscapeBackquote(text, backquoteIndexes)) {
    final firstBackquoteIndex = backquoteIndexes[0];
    final secondBackquoteIndex = backquoteIndexes[1];
    final lastBackquoteIndex = backquoteIndexes[backquoteIndexes.length - 1];
    if (secondBackquoteIndex == lastBackquoteIndex ||
        secondBackquoteIndex == lastBackquoteIndex - 1 ||
        lastBackquoteIndex != endIndex - 1) {
      // ``(`),```(`),``...`...(`) should ignored
      return KeyEventResult.ignored;
    }

    TransactionBuilder(editorState)
      ..deleteText(textNode, lastBackquoteIndex, 1)
      ..deleteText(textNode, firstBackquoteIndex, 2)
      ..formatText(
        textNode,
        firstBackquoteIndex,
        endIndex - firstBackquoteIndex - 3,
        {
          BuiltInAttributeKey.code: true,
        },
      )
      ..afterSelection = Selection.collapsed(
        Position(
          path: textNode.path,
          offset: endIndex - 3,
        ),
      )
      ..commit();

    return KeyEventResult.handled;
  }

  // handle single backquote
  final startIndex = backquoteIndexes[0];
  if (startIndex == endIndex - 1) {
    return KeyEventResult.ignored;
  }

  // delete the backquote.
  // update the style of the text surround by ` ` to code.
  // and update the cursor position.
  TransactionBuilder(editorState)
    ..deleteText(textNode, startIndex, 1)
    ..formatText(
      textNode,
      startIndex,
      endIndex - startIndex - 1,
      {
        BuiltInAttributeKey.code: true,
      },
    )
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: endIndex - 1,
      ),
    )
    ..commit();

  return KeyEventResult.handled;
};
