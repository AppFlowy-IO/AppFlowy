import 'package:appflowy/plugins/document/presentation/editor_plugins/toggle/toggle_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

const _greater = '>';

/// Convert '> ' to toggle list
///
/// - support
///   - desktop
///   - mobile
///   - web
///
CharacterShortcutEvent formatGreaterToToggleList = CharacterShortcutEvent(
  key: 'format greater to quote',
  character: ' ',
  handler: (editorState) async => await formatMarkdownSymbol(
    editorState,
    (node) => node.type != ToggleListBlockKeys.type,
    (_, text, __) => text == _greater,
    (_, node, delta) => toggleListBlockNode(
      delta: delta.compose(Delta()..delete(_greater.length)),
    ),
  ),
);

/// Press enter key to insert child node inside the toggle list
///
/// - support
///   - desktop
///   - mobile
///   - web
CharacterShortcutEvent insertChildNodeInsideToggleList = CharacterShortcutEvent(
  key: 'insert child node inside toggle list',
  character: '\n',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return false;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null || node.type != ToggleListBlockKeys.type) {
      return false;
    }
    final transaction = editorState.transaction;
    final collapsed = node.attributes[ToggleListBlockKeys.collapsed] as bool;
    if (collapsed) {
      // insert a toggle list block below the current toggle list block
      transaction
        ..insertNode(
          selection.start.path.next,
          toggleListBlockNode(collapsed: true),
        )
        ..afterSelection = Selection.collapse(selection.start.path.next, 0);
    } else {
      // insert a paragraph block inside the current toggle list block
      transaction
        ..insertNode(
          selection.start.path + [0],
          paragraphNode(),
        )
        ..afterSelection = Selection.collapse(selection.start.path + [0], 0);
    }
    await editorState.apply(transaction);
    return true;
  },
);
