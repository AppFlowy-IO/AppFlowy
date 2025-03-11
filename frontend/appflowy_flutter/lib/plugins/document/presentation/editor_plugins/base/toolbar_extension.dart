import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
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
