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

  bool isAllCheckboxesChecked = checkboxTextNodes
      .every((node) => node.attributes[BuiltInAttributeKey.checkbox] == true);
  final transaction = editorState.transaction;
  transaction.afterSelection = selection;

  if (isAllCheckboxesChecked) {
    //if all the checkboxes are checked, then make all of the checkboxes unchecked
    for (final node in checkboxTextNodes) {
      transaction.updateNode(node, {BuiltInAttributeKey.checkbox: false});
    }
  } else {
    //If any one of the checkboxes is unchecked then make all checkboxes checked
    for (final node in checkboxTextNodes) {
      transaction.updateNode(node, {BuiltInAttributeKey.checkbox: true});
    }
  }

  editorState.apply(transaction);
  return KeyEventResult.handled;
};
