import 'package:appflowy/plugins/document/presentation/editor_plugins/toggle/toggle_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

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
  handler: (editorState) async => formatMarkdownSymbol(
    editorState,
    (node) => node.type != ToggleListBlockKeys.type,
    (_, text, __) => text == _greater,
    (_, node, delta) {
      final type = node.type;
      int? level;
      if (type == ToggleListBlockKeys.type) {
        level = node.attributes[ToggleListBlockKeys.level] as int?;
      } else if (type == HeadingBlockKeys.type) {
        level = node.attributes[HeadingBlockKeys.level] as int?;
      }
      // if the previous block is heading block, convert it to toggle heading block
      if (type == HeadingBlockKeys.type && level != null) {
        return [
          toggleHeadingNode(
            level: level,
            delta: delta.compose(Delta()..delete(_greater.length)),
          ),
        ];
      }
      return [
        toggleListBlockNode(
          delta: delta.compose(Delta()..delete(_greater.length)),
        ),
      ];
    },
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
    final delta = node?.delta;
    if (node == null ||
        node.type != ToggleListBlockKeys.type ||
        delta == null) {
      return false;
    }
    final slicedDelta = delta.slice(selection.start.offset);
    final transaction = editorState.transaction;
    final collapsed = node.attributes[ToggleListBlockKeys.collapsed] as bool;
    if (collapsed) {
      // if the delta is empty, clear the format
      if (delta.isEmpty) {
        transaction
          ..insertNode(
            selection.start.path.next,
            paragraphNode(),
          )
          ..deleteNode(node)
          ..afterSelection = Selection.collapsed(
            Position(path: selection.start.path),
          );
      } else if (selection.startIndex == 0) {
        // insert a paragraph block above the current toggle list block
        transaction.insertNode(selection.start.path, paragraphNode());
        transaction.afterSelection = Selection.collapsed(
          Position(path: selection.start.path.next),
        );
      } else {
        // insert a toggle list block below the current toggle list block
        transaction
          ..deleteText(node, selection.startIndex, slicedDelta.length)
          ..insertNodes(
            selection.start.path.next,
            [
              toggleListBlockNode(collapsed: true, delta: slicedDelta),
              paragraphNode(),
            ],
          )
          ..afterSelection = Selection.collapsed(
            Position(path: selection.start.path.next),
          );
      }
    } else {
      // insert a paragraph block inside the current toggle list block
      transaction
        ..deleteText(node, selection.startIndex, slicedDelta.length)
        ..insertNode(
          selection.start.path + [0],
          paragraphNode(delta: slicedDelta),
        )
        ..afterSelection = Selection.collapsed(
          Position(path: selection.start.path + [0]),
        );
    }
    await editorState.apply(transaction);
    return true;
  },
);

/// cmd/ctrl + enter to close or open the toggle list
///
/// - support
///   - desktop
///   - web
///

// toggle the todo list
final CommandShortcutEvent toggleToggleListCommand = CommandShortcutEvent(
  key: 'toggle the toggle list',
  getDescription: () => AppFlowyEditorL10n.current.cmdToggleTodoList,
  command: 'ctrl+enter',
  macOSCommand: 'cmd+enter',
  handler: _toggleToggleListCommandHandler,
);

CommandShortcutEventHandler _toggleToggleListCommandHandler = (editorState) {
  if (UniversalPlatform.isMobile) {
    assert(false, 'enter key is not supported on mobile platform.');
    return KeyEventResult.ignored;
  }

  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  final nodes = editorState.getNodesInSelection(selection);
  if (nodes.isEmpty || nodes.length > 1) {
    return KeyEventResult.ignored;
  }

  final node = nodes.first;
  if (node.type != ToggleListBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  final collapsed = node.attributes[ToggleListBlockKeys.collapsed] as bool;
  final transaction = editorState.transaction;
  transaction.updateNode(node, {
    ToggleListBlockKeys.collapsed: !collapsed,
  });
  transaction.afterSelection = selection;
  editorState.apply(transaction);
  return KeyEventResult.handled;
};
