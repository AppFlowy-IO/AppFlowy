import 'dart:collection';
import 'dart:math';

import 'package:appflowy_editor/src/document/attributes.dart';
import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/document/text_delta.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/operation/operation.dart';
import 'package:appflowy_editor/src/operation/transaction.dart';

/// A [TransactionBuilder] is used to build the transaction from the state.
/// It will save a snapshot of the cursor selection state automatically.
/// The cursor can be restored if the transaction is undo.
class TransactionBuilder {
  final List<Operation> operations = [];
  EditorState state;
  Selection? beforeSelection;
  Selection? afterSelection;

  TransactionBuilder(this.state);

  /// Commits the operations to the state
  Future<void> commit() async {
    final transaction = finish();
    state.apply(transaction);
  }

  /// Inserts the nodes at the position of path.
  insertNode(Path path, Node node) {
    insertNodes(path, [node]);
  }

  /// Inserts a sequence of nodes at the position of path.
  insertNodes(Path path, List<Node> nodes) {
    beforeSelection = state.cursorSelection;
    add(InsertOperation(path, nodes.map((node) => node.deepClone()).toList()));
  }

  /// Updates the attributes of nodes.
  updateNode(Node node, Attributes attributes) {
    beforeSelection = state.cursorSelection;

    final inverted = invertAttributes(attributes, node.attributes);
    add(UpdateOperation(
      node.path,
      {...attributes},
      inverted,
    ));
  }

  /// Deletes a node in the document.
  deleteNode(Node node) {
    deleteNodesAtPath(node.path);
  }

  deleteNodes(List<Node> nodes) {
    nodes.forEach(deleteNode);
  }

  /// Deletes a sequence of nodes at the path of the document.
  /// The length specifies the length of the following nodes to delete(
  /// including the start one).
  deleteNodesAtPath(Path path, [int length = 1]) {
    if (path.isEmpty) {
      return;
    }
    final nodes = <Node>[];
    final prefix = path.sublist(0, path.length - 1);
    final last = path.last;
    for (var i = 0; i < length; i++) {
      final node = state.document.nodeAtPath(prefix + [last + i])!;
      nodes.add(node);
    }

    add(DeleteOperation(path, nodes.map((node) => node.deepClone()).toList()));
  }

  textEdit(TextNode node, Delta Function() f) {
    beforeSelection = state.cursorSelection;
    final path = node.path;

    final delta = f();

    final inverted = delta.invert(node.delta);

    add(TextEditOperation(path, delta, inverted));
  }

  setAfterSelection(Selection sel) {
    afterSelection = sel;
  }

  mergeText(TextNode firstNode, TextNode secondNode,
      {int? firstOffset, int secondOffset = 0}) {
    final firstLength = firstNode.delta.length;
    final secondLength = secondNode.delta.length;
    textEdit(
      firstNode,
      () => Delta()
        ..retain(firstOffset ?? firstLength)
        ..delete(firstLength - (firstOffset ?? firstLength))
        ..addAll(secondNode.delta.slice(secondOffset, secondLength)),
    );
    afterSelection = Selection.collapsed(
      Position(
        path: firstNode.path,
        offset: firstOffset ?? firstLength,
      ),
    );
  }

  /// Inserts content at a specified index.
  /// Optionally, you may specify formatting attributes that are applied to the inserted string.
  /// By default, the formatting attributes before the insert position will be used.
  insertText(
    TextNode node,
    int index,
    String content, {
    Attributes? attributes,
  }) {
    var newAttributes = attributes;
    if (index != 0 && attributes == null) {
      newAttributes =
          node.delta.slice(max(index - 1, 0), index).first.attributes;
      if (newAttributes != null) {
        newAttributes = Attributes.from(newAttributes);
      }
    }
    textEdit(
      node,
      () => Delta()
        ..retain(index)
        ..insert(
          content,
          newAttributes,
        ),
    );
    afterSelection = Selection.collapsed(
      Position(path: node.path, offset: index + content.length),
    );
  }

  /// Assigns formatting attributes to a range of text.
  formatText(TextNode node, int index, int length, Attributes attributes) {
    textEdit(
        node,
        () => Delta()
          ..retain(index)
          ..retain(length, attributes));
    afterSelection = beforeSelection;
  }

  /// Deletes length characters starting from index.
  deleteText(TextNode node, int index, int length) {
    textEdit(
        node,
        () => Delta()
          ..retain(index)
          ..delete(length));
    afterSelection =
        Selection.collapsed(Position(path: node.path, offset: index));
  }

  replaceText(TextNode node, int index, int length, String content,
      [Attributes? attributes]) {
    var newAttributes = attributes;
    if (attributes == null) {
      final ops = node.delta.slice(index, index + length);
      if (ops.isNotEmpty) {
        newAttributes = ops.first.attributes;
      }
    }
    textEdit(
      node,
      () => Delta()
        ..retain(index)
        ..delete(length)
        ..insert(content, newAttributes),
    );
    afterSelection = Selection.collapsed(
      Position(
        path: node.path,
        offset: index + content.length,
      ),
    );
  }

  /// Adds an operation to the transaction.
  /// This method will merge operations if they are both TextEdits.
  ///
  /// Also, this method will transform the path of the operations
  /// to avoid conflicts.
  add(Operation op) {
    final Operation? last = operations.isEmpty ? null : operations.last;
    if (last != null) {
      if (op is TextEditOperation &&
          last is TextEditOperation &&
          pathEquals(op.path, last.path)) {
        final newOp = TextEditOperation(
          op.path,
          last.delta.compose(op.delta),
          op.inverted.compose(last.inverted),
        );
        operations[operations.length - 1] = newOp;
        return;
      }
    }
    for (var i = 0; i < operations.length; i++) {
      op = transformOperation(operations[i], op);
    }
    if (op is TextEditOperation && op.delta.isEmpty) {
      return;
    }
    operations.add(op);
  }

  /// Generates a immutable [Transaction] to apply or transmit.
  Transaction finish() {
    return Transaction(
      operations: UnmodifiableListView(operations),
      beforeSelection: beforeSelection,
      afterSelection: afterSelection,
    );
  }
}
