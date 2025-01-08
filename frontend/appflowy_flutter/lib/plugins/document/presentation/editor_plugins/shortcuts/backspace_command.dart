import 'dart:math';

import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Backspace key event.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CommandShortcutEvent customBackspaceCommand = CommandShortcutEvent(
  key: 'backspace',
  getDescription: () => AppFlowyEditorL10n.current.cmdDeleteLeft,
  command: 'backspace, shift+backspace',
  handler: _backspaceCommandHandler,
);

CommandShortcutEventHandler _backspaceCommandHandler = (editorState) {
  final selection = editorState.selection;
  final selectionType = editorState.selectionType;

  if (selection == null) {
    return KeyEventResult.ignored;
  }

  final reason = editorState.selectionUpdateReason;

  if (selectionType == SelectionType.block) {
    return _backspaceInBlockSelection(editorState);
  } else if (selection.isCollapsed) {
    return _backspaceInCollapsedSelection(editorState);
  } else if (reason == SelectionUpdateReason.selectAll) {
    return _backspaceInSelectAll(editorState);
  } else {
    return _backspaceInNotCollapsedSelection(editorState);
  }
};

/// Handle backspace key event when selection is collapsed.
CommandShortcutEventHandler _backspaceInCollapsedSelection = (editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  final position = selection.start;
  final node = editorState.getNodeAtPath(position.path);
  if (node == null) {
    return KeyEventResult.ignored;
  }

  final transaction = editorState.transaction;

  // delete the entire node if the delta is empty
  if (node.delta == null) {
    transaction.deleteNode(node);
    transaction.afterSelection = Selection.collapsed(
      Position(
        path: position.path,
      ),
    );
    editorState.apply(transaction);
    return KeyEventResult.handled;
  }

  // Why do we use prevRunPosition instead of the position start offset?
  // Because some character's length > 1, for example, emoji.
  final index = node.delta!.prevRunePosition(position.offset);

  if (index < 0) {
    // move this node to it's parent in below case.
    // the node's next is null
    // and the node's children is empty
    if (node.next == null &&
        node.children.isEmpty &&
        node.parent?.parent != null &&
        node.parent?.delta != null) {
      final path = node.parent!.path.next;
      transaction
        ..deleteNode(node)
        ..insertNode(path, node)
        ..afterSelection = Selection.collapsed(
          Position(
            path: path,
          ),
        );
    } else {
      // If the deletion crosses columns and starts from the beginning position
      // skip the node deletion process
      // otherwise it will cause an error in table rendering.
      if (node.parent?.type == SimpleTableCellBlockKeys.type &&
          position.offset == 0) {
        return KeyEventResult.handled;
      }

      final Node? tableParent = node
          .findParent((element) => element.type == SimpleTableBlockKeys.type);
      Node? prevTableParent;
      final prev = node.previousNodeWhere((element) {
        prevTableParent = element
            .findParent((element) => element.type == SimpleTableBlockKeys.type);
        // break if only one is in a table or they're in different tables
        return tableParent != prevTableParent ||
            // merge with the previous node contains delta.
            element.delta != null;
      });
      // table nodes should be deleted using the table menu
      // in-table paragraphs should only be deleted inside the table
      if (prev != null && tableParent == prevTableParent) {
        assert(prev.delta != null);
        transaction
          ..mergeText(prev, node)
          ..insertNodes(
            // insert children to previous node
            prev.path.next,
            node.children.toList(),
          )
          ..deleteNode(node)
          ..afterSelection = Selection.collapsed(
            Position(
              path: prev.path,
              offset: prev.delta!.length,
            ),
          );
      } else {
        // do nothing if there is no previous node contains delta.
        return KeyEventResult.ignored;
      }
    }
  } else {
    // Although the selection may be collapsed,
    //  its length may not always be equal to 1 because some characters have a length greater than 1.
    transaction.deleteText(
      node,
      index,
      position.offset - index,
    );
  }

  editorState.apply(transaction);
  return KeyEventResult.handled;
};

/// Handle backspace key event when selection is not collapsed.
CommandShortcutEventHandler _backspaceInNotCollapsedSelection = (editorState) {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) {
    return KeyEventResult.ignored;
  }
  editorState.deleteSelectionV2(selection);
  return KeyEventResult.handled;
};

CommandShortcutEventHandler _backspaceInBlockSelection = (editorState) {
  final selection = editorState.selection;
  if (selection == null || editorState.selectionType != SelectionType.block) {
    return KeyEventResult.ignored;
  }
  final transaction = editorState.transaction;
  transaction.deleteNodesAtPath(selection.start.path);
  editorState
      .apply(transaction)
      .then((value) => editorState.selectionType = null);

  return KeyEventResult.handled;
};

CommandShortcutEventHandler _backspaceInSelectAll = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  final transaction = editorState.transaction;
  final nodes = editorState.getNodesInSelection(selection);
  transaction.deleteNodes(nodes);
  editorState.apply(transaction);

  return KeyEventResult.handled;
};

extension on EditorState {
  Future<bool> deleteSelectionV2(Selection selection) async {
    // Nothing to do if the selection is collapsed.
    if (selection.isCollapsed) {
      return false;
    }

    // Normalize the selection so that it is never reversed or extended.
    selection = selection.normalized;

    // Start a new transaction.
    final transaction = this.transaction;

    // Get the nodes that are fully or partially selected.
    final nodes = getNodesInSelection(selection);

    // If only one node is selected, then we can just delete the selected text
    // or node.
    if (nodes.length == 1) {
      // If table cell is selected, clear the cell node child.
      final node = nodes.first.type == SimpleTableCellBlockKeys.type
          ? nodes.first.children.first
          : nodes.first;
      if (node.delta != null) {
        transaction.deleteText(
          node,
          selection.startIndex,
          selection.length,
        );
      } else if (node.parent?.type != SimpleTableCellBlockKeys.type &&
          node.parent?.type != SimpleTableRowBlockKeys.type) {
        transaction.deleteNode(node);
      }
    }

    // Otherwise, multiple nodes are selected, so we have to do more work.
    else {
      // The nodes are guaranteed to be in order, so we can determine which
      // nodes are at the beginning, middle, and end of the selection.
      assert(nodes.first.path < nodes.last.path);
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];

        // The first node is at the beginning of the selection.
        // All other nodes can be deleted.
        if (i != 0) {
          // Never delete a table cell node child
          if (node.parent?.type == SimpleTableCellBlockKeys.type) {
            if (!nodes.any((n) => n.id == node.parent?.parent?.id) &&
                node.delta != null) {
              transaction.deleteText(
                node,
                0,
                min(selection.end.offset, node.delta!.length),
              );
            }
          }
          // If first node was inside table cell then it wasn't mergable to last
          // node, So we should not delete the last node. Just delete part of
          // the text inside selection
          else if (node.id == nodes.last.id &&
              nodes.first.parent?.type == SimpleTableCellBlockKeys.type) {
            transaction.deleteText(
              node,
              0,
              selection.end.offset,
            );
          } else if (node.type != SimpleTableCellBlockKeys.type &&
              node.type != SimpleTableRowBlockKeys.type) {
            transaction.deleteNode(node);
          }
          continue;
        }

        // If the last node is also a text node and not a node inside table cell,
        // and also the current node isn't inside table cell, then we can merge
        // the text between the two nodes.
        if (nodes.last.delta != null &&
            ![node.parent?.type, nodes.last.parent?.type]
                .contains(SimpleTableCellBlockKeys.type)) {
          transaction.mergeText(
            node,
            nodes.last,
            leftOffset: selection.startIndex,
            rightOffset: selection.endIndex,
          );

          // combine the children of the last node into the first node.
          final last = nodes.last;

          if (last.children.isNotEmpty) {
            if (indentableBlockTypes.contains(node.type)) {
              transaction.insertNodes(
                node.path + [0],
                last.children,
              );
            } else {
              transaction.insertNodes(
                node.path.next,
                last.children,
              );
            }
          }
        }

        // Otherwise, we can just delete the selected text.
        else {
          // If the last or first node is inside table we will only delete
          // selection part of first node.
          if (nodes.last.parent?.type == SimpleTableCellBlockKeys.type ||
              node.parent?.type == SimpleTableCellBlockKeys.type) {
            transaction.deleteText(
              node,
              selection.startIndex,
              node.delta!.length - selection.startIndex,
            );
          } else {
            transaction.deleteText(
              node,
              selection.startIndex,
              selection.length,
            );
          }
        }
      }
    }

    // After the selection is deleted, we want to move the selection to the
    // beginning of the deleted selection.
    transaction.afterSelection = selection.collapse(atStart: true);

    // Apply the transaction.
    await apply(transaction);

    return true;
  }
}
