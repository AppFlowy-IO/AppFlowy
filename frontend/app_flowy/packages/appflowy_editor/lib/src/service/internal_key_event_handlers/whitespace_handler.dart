import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/service/keyboard_service.dart';

@visibleForTesting
List<String> get checkboxListSymbols => _checkboxListSymbols;
@visibleForTesting
List<String> get unCheckboxListSymbols => _unCheckboxListSymbols;
@visibleForTesting
List<String> get bulletedListSymbols => _bulletedListSymbols;

const _bulletedListSymbols = ['*', '-'];
const _checkboxListSymbols = ['[x]', '-[x]'];
const _unCheckboxListSymbols = ['[]', '-[]'];

FlowyKeyEventHandler whiteSpaceHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.space) {
    return KeyEventResult.ignored;
  }

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
  final text = textNode.toRawString();
  if ((_checkboxListSymbols + _unCheckboxListSymbols).any(text.startsWith)) {
    return _toCheckboxList(editorState, textNode);
  } else if (_bulletedListSymbols.any(text.startsWith)) {
    return _toBulletedList(editorState, textNode);
  } else if (_countOfSign(text, selection) != 0) {
    return _toHeadingStyle(editorState, textNode, selection);
  }

  return KeyEventResult.ignored;
};

KeyEventResult _toBulletedList(EditorState editorState, TextNode textNode) {
  if (textNode.subtype == StyleKey.bulletedList) {
    return KeyEventResult.ignored;
  }
  TransactionBuilder(editorState)
    ..deleteText(textNode, 0, 1)
    ..updateNode(textNode, {
      StyleKey.subtype: StyleKey.bulletedList,
    })
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: 0,
      ),
    )
    ..commit();
  return KeyEventResult.handled;
}

KeyEventResult _toCheckboxList(EditorState editorState, TextNode textNode) {
  if (textNode.subtype == StyleKey.checkbox) {
    return KeyEventResult.ignored;
  }
  final String symbol;
  bool check = false;
  final symbols = List<String>.from(_checkboxListSymbols)
    ..retainWhere(textNode.toRawString().startsWith);
  if (symbols.isNotEmpty) {
    symbol = symbols.first;
    check = true;
  } else {
    symbol = (List<String>.from(_unCheckboxListSymbols)
          ..retainWhere(textNode.toRawString().startsWith))
        .first;
    check = false;
  }

  TransactionBuilder(editorState)
    ..deleteText(textNode, 0, symbol.length)
    ..updateNode(textNode, {
      StyleKey.subtype: StyleKey.checkbox,
      StyleKey.checkbox: check,
    })
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: 0,
      ),
    )
    ..commit();
  return KeyEventResult.handled;
}

KeyEventResult _toHeadingStyle(
    EditorState editorState, TextNode textNode, Selection selection) {
  final x = _countOfSign(
    textNode.toRawString(),
    selection,
  );
  final hX = 'h$x';
  if (textNode.attributes.heading == hX) {
    return KeyEventResult.ignored;
  }
  TransactionBuilder(editorState)
    ..deleteText(textNode, 0, x)
    ..updateNode(textNode, {
      StyleKey.subtype: StyleKey.heading,
      StyleKey.heading: hX,
    })
    ..afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: 0,
      ),
    )
    ..commit();
  return KeyEventResult.handled;
}

int _countOfSign(String text, Selection selection) {
  for (var i = 6; i >= 0; i--) {
    if (text.substring(0, selection.end.offset).startsWith('#' * i)) {
      return i;
    }
  }
  return 0;
}
