import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

ShortcutEventHandler toggleCheckbox = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  final checkboxTextNodes = nodes
      .where(
        (element) =>
            element is TextNode &&
            element.subtype == BuiltInAttributeKey.checkbox,
      )
      .toList(growable: false);

  if (selection == null || checkboxTextNodes.isEmpty) {
    return KeyEventResult.ignored;
  }

  //If any one of the checkboxes is unchecked then make all checkboxes checked

  bool isAllCheckboxesChecked = true;
  final transaction = editorState.transaction;
  for (final node in checkboxTextNodes) {
    if (node.attributes[BuiltInAttributeKey.checkbox] == false) {
      isAllCheckboxesChecked = false;
      transaction.updateNode(node, {
        BuiltInAttributeKey.checkbox:
            !node.attributes[BuiltInAttributeKey.checkbox]
      });
    }
  }
  editorState.apply(transaction);

  //if all the checkboxes are checked, then make all of the checkboxes unchecked
  final transaction2 = editorState.transaction;
  if (isAllCheckboxesChecked) {
    for (final node in checkboxTextNodes) {
      transaction2.updateNode(node, {
        BuiltInAttributeKey.checkbox:
            !node.attributes[BuiltInAttributeKey.checkbox]
      });
    }
  }
  editorState.apply(transaction2);
  return KeyEventResult.handled;
};
