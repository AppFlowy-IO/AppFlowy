import 'package:appflowy_editor/appflowy_editor.dart';

extension PasteNodes on EditorState {
  Future<void> pasteSingleLineNode(Node insertedNode) async {
    final selection = await deleteSelectionIfNeeded();
    if (selection == null) {
      return;
    }
    final node = getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final transaction = this.transaction;
    final insertedDelta = insertedNode.delta;
    // if the node is empty and its type is paragprah, replace it with the inserted node.
    if (delta.isEmpty && node.type == ParagraphBlockKeys.type) {
      transaction.insertNode(
        selection.end.path.next,
        insertedNode,
      );
      transaction.deleteNode(node);
      final path = calculatePath(selection.end.path, [insertedNode]);
      final offset = calculateLength([insertedNode]);
      transaction.afterSelection = Selection.collapsed(
        Position(
          path: path,
          offset: offset,
        ),
      );
    } else if (insertedDelta != null) {
      // if the node is not empty, insert the delta from inserted node after the selection.
      transaction.insertTextDelta(node, selection.endIndex, insertedDelta);
    }
    await apply(transaction);
  }

  Future<void> pasteMultiLineNodes(List<Node> nodes) async {
    assert(nodes.length > 1);

    final selection = await deleteSelectionIfNeeded();
    if (selection == null) {
      return;
    }
    final node = getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final transaction = this.transaction;

    final lastNodeLength = calculateLength(nodes);
    // merge the current selected node delta into the nodes.
    if (delta.isNotEmpty) {
      nodes.first.insertDelta(
        delta.slice(0, selection.startIndex),
        insertAfter: false,
      );

      nodes.last.insertDelta(
        delta.slice(selection.endIndex),
      );
    }

    if (delta.isEmpty && node.type != ParagraphBlockKeys.type) {
      nodes[0] = nodes.first.copyWith(
        type: node.type,
        attributes: {
          ...node.attributes,
          ...nodes.first.attributes,
        },
      );
    }

    for (final child in node.children) {
      nodes.last.insert(child);
    }

    transaction.insertNodes(selection.end.path, nodes);

    // delete the current node.
    transaction.deleteNode(node);

    final path = calculatePath(selection.start.path, nodes);
    transaction.afterSelection = Selection.collapsed(
      Position(
        path: path,
        offset: lastNodeLength,
      ),
    );

    await apply(transaction);
  }

  // delete the selection if it's not collapsed.
  Future<Selection?> deleteSelectionIfNeeded() async {
    final selection = this.selection;
    if (selection == null) {
      return null;
    }

    // delete the selection first.
    if (!selection.isCollapsed) {
      await deleteSelection(selection);
    }

    // fetch selection again.selection = editorState.selection;
    assert(this.selection?.isCollapsed == true);
    return this.selection;
  }

  Path calculatePath(Path start, List<Node> nodes) {
    var path = start;
    for (var i = 0; i < nodes.length; i++) {
      path = path.next;
    }
    path = path.previous;
    if (nodes.last.children.isNotEmpty) {
      return [
        ...path,
        ...calculatePath([0], nodes.last.children.toList()),
      ];
    }
    return path;
  }

  int calculateLength(List<Node> nodes) {
    if (nodes.last.children.isNotEmpty) {
      return calculateLength(nodes.last.children.toList());
    }
    return nodes.last.delta?.length ?? 0;
  }
}

extension on Node {
  void insertDelta(Delta delta, {bool insertAfter = true}) {
    assert(delta.every((element) => element is TextInsert));
    if (this.delta == null) {
      updateAttributes({
        blockComponentDelta: delta.toJson(),
      });
    } else if (insertAfter) {
      updateAttributes(
        {
          blockComponentDelta: this
              .delta!
              .compose(
                Delta()
                  ..retain(this.delta!.length)
                  ..addAll(delta),
              )
              .toJson(),
        },
      );
    } else {
      updateAttributes(
        {
          blockComponentDelta: delta
              .compose(
                Delta()
                  ..retain(delta.length)
                  ..addAll(this.delta!),
              )
              .toJson(),
        },
      );
    }
  }
}
