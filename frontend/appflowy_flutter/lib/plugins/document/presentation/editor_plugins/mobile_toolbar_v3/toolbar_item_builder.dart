import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final _listBlockTypes = [
  BulletedListBlockKeys.type,
  NumberedListBlockKeys.type,
  TodoListBlockKeys.type,
];

final _defaultToolbarItems = [
  addBlockToolbarItem,
  aaToolbarItem,
  todoListToolbarItem,
  bulletedListToolbarItem,
  numberedListToolbarItem,
  boldToolbarItem,
  italicToolbarItem,
  underlineToolbarItem,
  strikethroughToolbarItem,
  colorToolbarItem,
  undoToolbarItem,
  redoToolbarItem,
];

final _listToolbarItems = [
  addBlockToolbarItem,
  aaToolbarItem,
  outdentToolbarItem,
  indentToolbarItem,
  todoListToolbarItem,
  bulletedListToolbarItem,
  numberedListToolbarItem,
  boldToolbarItem,
  italicToolbarItem,
  underlineToolbarItem,
  strikethroughToolbarItem,
  colorToolbarItem,
  undoToolbarItem,
  redoToolbarItem,
];

final _textToolbarItems = [
  aaToolbarItem,
  boldToolbarItem,
  italicToolbarItem,
  underlineToolbarItem,
  strikethroughToolbarItem,
  colorToolbarItem,
];

/// Calculate the toolbar items based on the current selection.
///
/// Default:
///   Add, Aa, Todo List, Image, Bulleted List, Numbered List, B, I, U, S, Color, Undo, Redo
///
/// Selecting text:
///   Aa, B, I, U, S, Color
///
/// Selecting a list:
///   Add, Aa, Indent, Outdent, Bulleted List, Numbered List, Todo List B, I, U, S
List<AppFlowyMobileToolbarItem> buildMobileToolbarItems(
  EditorState editorState,
  Selection? selection,
) {
  if (selection == null) {
    return [];
  }

  if (!selection.isCollapsed) {
    return _textToolbarItems;
  }

  final allSelectedAreListType = editorState
      .getSelectedNodes(selection: selection)
      .every((node) => _listBlockTypes.contains(node.type));
  if (allSelectedAreListType) {
    return _listToolbarItems;
  }

  return _defaultToolbarItems;
}
