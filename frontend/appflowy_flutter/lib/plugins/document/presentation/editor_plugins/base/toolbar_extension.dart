import 'dart:ui';

import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toggle/toggle_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

bool _isTableType(String type) {
  return [TableBlockKeys.type, SimpleTableBlockKeys.type].contains(type);
}

bool notShowInTable(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.every((element) {
    if (_isTableType(element.type)) {
      return false;
    }
    var parent = element.parent;
    while (parent != null) {
      if (_isTableType(parent.type)) {
        return false;
      }
      parent = parent.parent;
    }
    return true;
  });
}

bool onlyShowInSingleTextTypeSelectionAndExcludeTable(
  EditorState editorState,
) {
  return onlyShowInSingleSelectionAndTextType(editorState) &&
      notShowInTable(editorState);
}

bool enableSuggestions(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isSingle) {
    return false;
  }
  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null) {
    return false;
  }
  if (isNarrowWindow(editorState)) return false;

  return (node.delta != null && suggestionsItemTypes.contains(node.type)) &&
      notShowInTable(editorState);
}

bool isNarrowWindow(EditorState editorState) {
  final editorSize = editorState.renderBox?.size ?? Size.zero;
  if (editorSize.width < 650) return true;
  return false;
}

final Set<String> suggestionsItemTypes = {
  ...toolbarItemWhiteList,
  ToggleListBlockKeys.type,
  TodoListBlockKeys.type,
  CalloutBlockKeys.type,
};
