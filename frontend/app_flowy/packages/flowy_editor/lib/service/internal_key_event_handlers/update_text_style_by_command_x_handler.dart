import 'package:flutter/material.dart';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/extensions/text_node_extensions.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/service/default_text_operations/format_rich_text_style.dart';
import 'package:flowy_editor/service/keyboard_service.dart';

FlowyKeyEventHandler updateTextStyleByCommandXHandler = (editorState, event) {
  if (!event.isMetaPressed || event.character == null) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.service.selectionService.currentSelection;
  final nodes = editorState.service.selectionService.currentSelectedNodes.value;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);

  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }

  switch (event.character!) {
    // bold
    case 'B':
    case 'b':
      formatBold(editorState);
      return KeyEventResult.handled;
    default:
      break;
  }

  return KeyEventResult.ignored;
};
