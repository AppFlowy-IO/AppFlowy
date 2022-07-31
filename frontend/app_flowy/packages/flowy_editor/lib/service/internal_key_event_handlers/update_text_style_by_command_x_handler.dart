import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flutter/material.dart';

FlowyKeyEventHandler updateTextStyleByCommandXHandler = (editorState, event) {
  if (!event.isMetaPressed || event.character == null) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.service.selectionService.currentSelection;
  final nodes = editorState.service.selectionService.currentSelectedNodes.value
      .whereType<TextNode>()
      .toList();

  if (selection == null || nodes.isEmpty) {
    return KeyEventResult.ignored;
  }

  switch (event.character!) {
    // bold
    case 'B':
    case 'b':
      _makeBold(editorState, nodes, selection);
      return KeyEventResult.handled;
    default:
      break;
  }

  return KeyEventResult.ignored;
};

// TODO: implement unBold.
void _makeBold(
    EditorState editorState, List<TextNode> nodes, Selection selection) {
  final builder = TransactionBuilder(editorState);
  if (nodes.length == 1) {
    builder.formatText(
      nodes.first,
      selection.start.offset,
      selection.end.offset - selection.start.offset,
      {
        'bold': true,
      },
    );
  } else {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (i == 0) {
        builder.formatText(
          node,
          selection.start.offset,
          node.toRawString().length - selection.start.offset,
          {
            'bold': true,
          },
        );
      } else if (i == nodes.length - 1) {
        builder.formatText(
          node,
          0,
          selection.end.offset,
          {
            'bold': true,
          },
        );
      } else {
        builder.formatText(
          node,
          0,
          node.toRawString().length,
          {
            'bold': true,
          },
        );
      }
    }
  }
  builder.commit();
}
