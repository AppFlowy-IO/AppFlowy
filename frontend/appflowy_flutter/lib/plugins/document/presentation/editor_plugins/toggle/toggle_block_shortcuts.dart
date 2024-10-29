import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
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
  key: 'format greater to toggle list',
  character: ' ',
  handler: (editorState) async => _formatGreaterSymbol(
    editorState,
    (node) => node.type != ToggleListBlockKeys.type,
    (_, text, __) => text == _greater,
    (text, node, delta, afterSelection) async => _formatGreaterToToggleHeading(
      editorState,
      text,
      node,
      delta,
      afterSelection,
    ),
  ),
);

Future<void> _formatGreaterToToggleHeading(
  EditorState editorState,
  String text,
  Node node,
  Delta delta,
  Selection afterSelection,
) async {
  final type = node.type;
  int? level;
  if (type == ToggleListBlockKeys.type) {
    level = node.attributes[ToggleListBlockKeys.level] as int?;
  } else if (type == HeadingBlockKeys.type) {
    level = node.attributes[HeadingBlockKeys.level] as int?;
  }
  delta = delta.compose(Delta()..delete(_greater.length));
  // if the previous block is heading block, convert it to toggle heading block
  if (type == HeadingBlockKeys.type && level != null) {
    final cubit = BlockActionOptionCubit(
      editorState: editorState,
      blockComponentBuilder: {},
    );
    await cubit.turnIntoSingleToggleHeading(
      type: ToggleListBlockKeys.type,
      selectedNodes: [node],
      level: level,
      delta: delta,
      afterSelection: afterSelection,
    );
    return;
  }

  final transaction = editorState.transaction;
  transaction
    ..insertNode(
      node.path,
      toggleListBlockNode(
        delta: delta,
      ),
    )
    ..deleteNode(node);
  transaction.afterSelection = afterSelection;
  await editorState.apply(transaction);
}

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

/// Press the backspace at the first position of first line to go to the title
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent removeToggleHeadingStyle = CommandShortcutEvent(
  key: 'remove toggle heading style',
  command: 'backspace',
  getDescription: () => 'remove toggle heading style',
  handler: (editorState) => _removeToggleHeadingStyle(
    editorState: editorState,
  ),
);

// convert the toggle heading block to heading block
KeyEventResult _removeToggleHeadingStyle({
  required EditorState editorState,
}) {
  final selection = editorState.selection;
  if (selection == null ||
      !selection.isCollapsed ||
      selection.start.offset != 0) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null || node.type != ToggleListBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  final level = node.attributes[ToggleListBlockKeys.level] as int?;
  if (level == null) {
    return KeyEventResult.ignored;
  }

  final transaction = editorState.transaction;
  transaction.updateNode(node, {
    ToggleListBlockKeys.level: null,
  });
  transaction.afterSelection = selection;
  editorState.apply(transaction);

  return KeyEventResult.handled;
}

/// Formats the current node to specified markdown style.
///
/// For example,
///   bulleted list: '- '
///   numbered list: '1. '
///   quote: '" '
///   ...
///
/// The [nodeBuilder] can return a list of nodes, which will be inserted
///   into the document.
/// For example, when converting a bulleted list to a heading and the heading is
///  not allowed to contain children, then the [nodeBuilder] should return a list
///  of nodes, which contains the heading node and the children nodes.
Future<bool> _formatGreaterSymbol(
  EditorState editorState,
  bool Function(Node node) shouldFormat,
  bool Function(
    Node node,
    String text,
    Selection selection,
  ) predicate,
  Future<void> Function(
    String text,
    Node node,
    Delta delta,
    Selection afterSelection,
  ) onFormat,
) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }

  final position = selection.end;
  final node = editorState.getNodeAtPath(position.path);

  if (node == null || !shouldFormat(node)) {
    return false;
  }

  // Get the text from the start of the document until the selection.
  final delta = node.delta;
  if (delta == null) {
    return false;
  }
  final text = delta.toPlainText().substring(0, selection.end.offset);

  // If the text doesn't match the predicate, then we don't want to
  // format it.
  if (!predicate(node, text, selection)) {
    return false;
  }

  final afterSelection = Selection.collapsed(
    Position(
      path: node.path,
    ),
  );

  await onFormat(text, node, delta, afterSelection);

  return true;
}
