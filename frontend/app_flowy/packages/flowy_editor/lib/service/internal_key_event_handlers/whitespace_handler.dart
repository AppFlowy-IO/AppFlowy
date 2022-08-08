import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/service/keyboard_service.dart';

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

  final builder = TransactionBuilder(editorState);
  final textNode = textNodes.first;
  final text = textNode.toRawString();
  if (text == '*' || text == '-') {
    builder
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

  return KeyEventResult.ignored;
};
