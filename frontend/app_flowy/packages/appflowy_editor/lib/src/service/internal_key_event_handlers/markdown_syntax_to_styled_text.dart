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
      .toPlainText()
      .substring(selection.start.offset, selection.end.offset);

  // toggle code style when selected some text
  if (selectionText.isNotEmpty) {
    formatEmbedCode(editorState);
    return KeyEventResult.handled;
  }

  final text = textNode.toPlainText().substring(0, selection.end.offset);
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

    editorState.transaction
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
      );
    editorState.commit();

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
  editorState.transaction
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
    );
  editorState.commit();

  return KeyEventResult.handled;
};

// convert ~~abc~~ to strikethrough abc.
ShortcutEventHandler doubleTildeToStrikethrough = (editorState, event) {
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final text = textNode.toPlainText().substring(0, selection.end.offset);

  // make sure the last two characters are ~~.
  if (text.length < 2 || text[selection.end.offset - 1] != '~') {
    return KeyEventResult.ignored;
  }

  // find all the index of `~`.
  final tildeIndexes = <int>[];
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '~') {
      tildeIndexes.add(i);
    }
  }

  if (tildeIndexes.length < 3) {
    return KeyEventResult.ignored;
  }

  // make sure the second to last and third to last tildes are connected.
  final thirdToLastTildeIndex = tildeIndexes[tildeIndexes.length - 3];
  final secondToLastTildeIndex = tildeIndexes[tildeIndexes.length - 2];
  final lastTildeIndex = tildeIndexes[tildeIndexes.length - 1];
  if (secondToLastTildeIndex != thirdToLastTildeIndex + 1 ||
      lastTildeIndex == secondToLastTildeIndex + 1) {
    return KeyEventResult.ignored;
  }

  // delete the last three tildes.
  // update the style of the text surround by `~~ ~~` to strikethrough.
  // and update the cursor position.
  editorState.transaction
    ..deleteText(textNode, lastTildeIndex, 1)
    ..deleteText(textNode, thirdToLastTildeIndex, 2)
    ..formatText(
      textNode,
      thirdToLastTildeIndex,
      selection.end.offset - thirdToLastTildeIndex - 2,
      {
        BuiltInAttributeKey.strikethrough: true,
      },
    )
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: selection.end.offset - 3,
      ),
    );
  editorState.commit();

  return KeyEventResult.handled;
};

/// To create a link, enclose the link text in brackets (e.g., [link text]).
/// Then, immediately follow it with the URL in parentheses (e.g., (https://example.com)).
ShortcutEventHandler markdownLinkToLinkHandler = (editorState, event) {
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  // find all of the indexs for important characters
  final textNode = textNodes.first;
  final text = textNode.toPlainText();
  final firstOpeningBracket = text.indexOf('[');
  final firstClosingBracket = text.indexOf(']');

  // use regex to validate the format of the link
  // note: this enforces that the link has http or https
  final regexp = RegExp(r'\[([\w\s\d]+)\]\(((?:\/|https?:\/\/)[\w\d./?=#]+)$');
  final match = regexp.firstMatch(text);
  if (match == null) {
    return KeyEventResult.ignored;
  }

  // extract the text and the url of the link
  final linkText = match.group(1);
  final linkUrl = match.group(2);

  // Delete the initial opening bracket,
  // update the href attribute of the text surrounded by [ ] to the url,
  // delete everything after the text,
  // and update the cursor position.
  editorState.transaction
    ..deleteText(textNode, firstOpeningBracket, 1)
    ..formatText(
      textNode,
      firstOpeningBracket,
      firstClosingBracket - firstOpeningBracket - 1,
      {
        BuiltInAttributeKey.href: linkUrl,
      },
    )
    ..deleteText(textNode, firstClosingBracket - 1,
        selection.end.offset - firstClosingBracket)
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: firstOpeningBracket + linkText!.length,
      ),
    );
  editorState.commit();

  return KeyEventResult.handled;
};
