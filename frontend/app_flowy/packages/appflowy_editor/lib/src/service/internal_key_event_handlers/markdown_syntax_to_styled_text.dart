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

    final transaction = editorState.transaction
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
    editorState.apply(transaction);

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
  final transaction = editorState.transaction
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
  editorState.apply(transaction);

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
  final transaction = editorState.transaction
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
  editorState.apply(transaction);

  return KeyEventResult.handled;
};

ShortcutEventHandler markdownLinkOrImageHandler = (editorState, event) {
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  // Find all of the indexes of the relevant characters
  final textNode = textNodes.first;
  final text = textNode.toPlainText();
  final firstExclamation = text.indexOf('!');
  final firstOpeningBracket = text.indexOf('[');
  final firstClosingBracket = text.indexOf(']');

  // Use RegEx to determine whether it's an image or a link
  // Difference between image and link syntax is that image
  // has an exclamation point at the beginning.
  // Note: The RegEx enforces that the URL has http or https
  final imgRegEx =
      RegExp(r'\!\[([\w\s\d]+)\]\(((?:\/|https?:\/\/)[\w\d-./?=#%&]+)$');
  final lnkRegEx =
      RegExp(r'\[([\w\s\d]+)\]\(((?:\/|https?:\/\/)[\w\d-./?=#%&]+)$');

  if (imgRegEx.firstMatch(text) != null) {
    // Extract the alt text and the URL of the image
    final match = lnkRegEx.firstMatch(text);
    final imgUrl = match?.group(2);

    // Delete the text and replace it with the image pointed to by the URL
    final transaction = editorState.transaction
      ..deleteText(textNode, firstExclamation, text.length)
      ..insertNode(
          textNode.path,
          Node.fromJson({
            'type': 'image',
            'attributes': {
              'image_src': imgUrl,
              'align': 'center',
            }
          }));
    editorState.apply(transaction);
  } else if (lnkRegEx.firstMatch(text) != null) {
    // Extract the text and the URL of the link
    final match = lnkRegEx.firstMatch(text);
    final linkText = match?.group(1);
    final linkUrl = match?.group(2);

    // Delete the initial opening bracket,
    // update the href attribute of the text surrounded by [ ] to the url,
    // delete everything after the text,
    // and update the cursor position.
    final transaction = editorState.transaction
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
    editorState.apply(transaction);
  } else {
    return KeyEventResult.ignored;
  }
  return KeyEventResult.handled;
};

// convert **abc** to bold abc.
ShortcutEventHandler doubleAsterisksToBold = (editorState, event) {
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final text = textNode.toPlainText().substring(0, selection.end.offset);

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
  final transaction = editorState.transaction
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
    );
  editorState.apply(transaction);

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
  final text = textNode.toPlainText().substring(0, selection.end.offset);

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
  final transaction = editorState.transaction
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
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
};

ShortcutEventHandler underscoreToItalicHandler = (editorState, event) {
  // Obtain the selection and selected nodes of the current document through the 'selectionService'
  // to determine whether the selection is collapsed and whether the selected node is a text node.
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final text = textNode.toPlainText();
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
  final transaction = editorState.transaction
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
    );
  editorState.apply(transaction);

  return KeyEventResult.handled;
};
