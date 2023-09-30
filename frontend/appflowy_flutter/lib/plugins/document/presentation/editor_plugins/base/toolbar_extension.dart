import 'package:appflowy_editor/appflowy_editor.dart';

bool notShowInTable(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.every((element) {
    if (element.type == TableBlockKeys.type) {
      return false;
    }
    var parent = element.parent;
    while (parent != null) {
      if (parent.type == TableBlockKeys.type) {
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
