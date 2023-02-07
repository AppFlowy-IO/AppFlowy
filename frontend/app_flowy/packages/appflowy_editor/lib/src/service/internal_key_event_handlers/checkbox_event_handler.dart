import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';
import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:flutter/material.dart';

ShortcutEventHandler toggleCheckbox = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final textNodes = nodes.whereType<TextNode>().toList(growable: false);
  if (selection == null || textNodes.isEmpty) {
    return KeyEventResult.ignored;
  }
  for (Node node in textNodes) {
    if (node.attributes.containsKey('checkbox') &&
        node.attributes.containsValue('checkbox')) {
      bool currentStatus = !(node.attributes['checkbox']);
      Attributes checkboxAttribute = {'checkbox': currentStatus};
      node.updateAttributes(checkboxAttribute);
    }
  }
  return KeyEventResult.handled;
};
