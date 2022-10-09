import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';

// get formatted [TextNode]
TextNode getTextNodeToBeFormatted(
  EditorState editorState, {
  Path? path,
  TextNode? textNode,
}) {
  final currentSelection =
      editorState.service.selectionService.currentSelection.value;
  TextNode result;
  if (textNode != null) {
    result = textNode;
  } else if (path != null) {
    result = editorState.document.nodeAtPath(path) as TextNode;
  } else if (currentSelection != null && currentSelection.isCollapsed) {
    result = editorState.document.nodeAtPath(currentSelection.start.path)
        as TextNode;
  } else {
    throw Exception('path and textNode cannot be null at the same time');
  }
  return result;
}

Selection getSelection(
  EditorState editorState, {
  Selection? selection,
}) {
  final currentSelection =
      editorState.service.selectionService.currentSelection.value;
  Selection result;
  if (selection != null) {
    result = selection;
  } else if (currentSelection != null) {
    result = currentSelection;
  } else {
    throw Exception('path and textNode cannot be null at the same time');
  }
  return result;
}
