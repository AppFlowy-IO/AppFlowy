import 'package:appflowy_editor/src/core/transform/transaction.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/core/legacy/built_in_attribute_keys.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import './number_list_helper.dart';
import 'package:appflowy_editor/src/extensions/attributes_extension.dart';

@visibleForTesting
List<String> get checkboxListSymbols => _checkboxListSymbols;
@visibleForTesting
List<String> get unCheckboxListSymbols => _unCheckboxListSymbols;
@visibleForTesting
List<String> get bulletedListSymbols => _bulletedListSymbols;

const _bulletedListSymbols = ['*', '-'];
const _checkboxListSymbols = ['[x]', '-[x]'];
const _unCheckboxListSymbols = ['[]', '-[]'];

final _numberRegex = RegExp(r'^(\d+)\.');

ShortcutEventHandler whiteSpaceHandler = (editorState, event) {
  /// Process markdown input style.
  ///
  /// like, #, *, -, 1., -[],

  final selection = editorState.service.selectionService.currentSelection.value;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  final textNodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  if (textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final textNode = textNodes.first;
  final text = textNode.toPlainText().substring(0, selection.end.offset);

  final numberMatch = _numberRegex.firstMatch(text);

  if ((_checkboxListSymbols + _unCheckboxListSymbols).contains(text)) {
    return _toCheckboxList(editorState, textNode);
  } else if (_bulletedListSymbols.contains(text)) {
    return _toBulletedList(editorState, textNode);
  } else if (_countOfSign(text, selection) != 0) {
    return _toHeadingStyle(editorState, textNode, selection);
  } else if (numberMatch != null) {
    final matchText = numberMatch.group(0);
    final numText = numberMatch.group(1);
    if (matchText != null && numText != null) {
      return _toNumberList(editorState, textNode, matchText, numText);
    }
  }

  return KeyEventResult.ignored;
};

KeyEventResult _toNumberList(EditorState editorState, TextNode textNode,
    String matchText, String numText) {
  if (textNode.subtype == BuiltInAttributeKey.bulletedList) {
    return KeyEventResult.ignored;
  }

  final numValue = int.tryParse(numText);
  if (numValue == null) {
    return KeyEventResult.ignored;
  }

  // The user types number + . + space, he wants to turn
  // this line into number list, but we should check if previous line
  // is number list.
  //
  // Check whether the number input by the user is the successor of the previous
  // line. If it's not, ignore it.
  final prevNode = textNode.previous;
  if (prevNode != null &&
      prevNode is TextNode &&
      prevNode.attributes[BuiltInAttributeKey.subtype] ==
          BuiltInAttributeKey.numberList) {
    final prevNumber = prevNode.attributes[BuiltInAttributeKey.number] as int;
    if (numValue != prevNumber + 1) {
      return KeyEventResult.ignored;
    }
  }

  final afterSelection = Selection.collapsed(Position(
    path: textNode.path,
    offset: 0,
  ));

  final insertPath = textNode.path;
  final transaction = editorState.transaction
    ..deleteText(textNode, 0, matchText.length)
    ..updateNode(textNode, {
      BuiltInAttributeKey.subtype: BuiltInAttributeKey.numberList,
      BuiltInAttributeKey.number: numValue
    })
    ..afterSelection = afterSelection;
  editorState.apply(transaction);

  makeFollowingNodesIncremental(editorState, insertPath, afterSelection);

  return KeyEventResult.handled;
}

KeyEventResult _toBulletedList(EditorState editorState, TextNode textNode) {
  if (textNode.subtype == BuiltInAttributeKey.bulletedList) {
    return KeyEventResult.ignored;
  }
  final transaction = editorState.transaction
    ..deleteText(textNode, 0, 1)
    ..updateNode(textNode, {
      BuiltInAttributeKey.subtype: BuiltInAttributeKey.bulletedList,
    })
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: 0,
      ),
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
}

KeyEventResult _toCheckboxList(EditorState editorState, TextNode textNode) {
  if (textNode.subtype == BuiltInAttributeKey.checkbox) {
    return KeyEventResult.ignored;
  }
  final String symbol;
  bool check = false;
  final symbols = List<String>.from(_checkboxListSymbols)
    ..retainWhere(textNode.toPlainText().startsWith);
  if (symbols.isNotEmpty) {
    symbol = symbols.first;
    check = true;
  } else {
    symbol = (List<String>.from(_unCheckboxListSymbols)
          ..retainWhere(textNode.toPlainText().startsWith))
        .first;
    check = false;
  }

  final transaction = editorState.transaction
    ..deleteText(textNode, 0, symbol.length)
    ..updateNode(textNode, {
      BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
      BuiltInAttributeKey.checkbox: check,
    })
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: 0,
      ),
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
}

KeyEventResult _toHeadingStyle(
    EditorState editorState, TextNode textNode, Selection selection) {
  final x = _countOfSign(
    textNode.toPlainText(),
    selection,
  );
  final hX = 'h$x';
  if (textNode.attributes.heading == hX) {
    return KeyEventResult.ignored;
  }
  final transaction = editorState.transaction
    ..deleteText(textNode, 0, x)
    ..updateNode(textNode, {
      BuiltInAttributeKey.subtype: BuiltInAttributeKey.heading,
      BuiltInAttributeKey.heading: hX,
    })
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: 0,
      ),
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
}

int _countOfSign(String text, Selection selection) {
  for (var i = 6; i >= 0; i--) {
    final heading = text.substring(0, selection.end.offset);
    if (heading.contains('#' * i) && heading.length == i) {
      return i;
    }
  }
  return 0;
}
