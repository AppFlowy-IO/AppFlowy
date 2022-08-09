import 'dart:collection';
import 'dart:math';

import 'package:flowy_editor/document/attributes.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/operation/operation.dart';
import 'package:flowy_editor/operation/transaction.dart';

/// A [TransactionBuilder] is used to build the transaction from the state.
/// It will save make a snapshot of the cursor selection state automatically.
/// The cursor can be resorted if the transaction is undo.

class TransactionBuilder {
  final List<Operation> operations = [];
  EditorState state;
  Selection? beforeSelection;
  Selection? afterSelection;

  TransactionBuilder(this.state);

  /// Commit the operations to the state
  commit() {
    final transaction = finish();
    state.apply(transaction);
  }

  insertNode(Path path, Node node) {
    insertNodes(path, [node]);
  }

  insertNodes(Path path, List<Node> nodes) {
    beforeSelection = state.cursorSelection;
    add(InsertOperation(path, nodes));
  }

  updateNode(Node node, Attributes attributes) {
    beforeSelection = state.cursorSelection;
    add(UpdateOperation(
      node.path,
      Attributes.from(node.attributes)..addAll(attributes),
      node.attributes,
    ));
  }

  deleteNode(Node node) {
    deleteNodesAtPath(node.path);
  }

  deleteNodes(List<Node> nodes) {
    nodes.forEach(deleteNode);
  }

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

    add(DeleteOperation(path, nodes));
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
        ..addAll(secondNode.delta.slice(secondOffset, secondLength).operations),
    );
    afterSelection = Selection.collapsed(
      Position(
        path: firstNode.path,
        offset: firstOffset ?? firstLength,
      ),
    );
  }

  insertText(TextNode node, int index, String content,
      [Attributes? attributes]) {
    textEdit(
      node,
      () => Delta().retain(index).insert(
            content,
            attributes ??
                (index == 0
                    ? null
                    : node.delta
                        .slice(max(index - 1, 0), index)
                        .operations
                        .first
                        .attributes),
          ),
    );
    afterSelection = Selection.collapsed(
        Position(path: node.path, offset: index + content.length));
  }

  formatText(TextNode node, int index, int length, Attributes attributes) {
    textEdit(node, () => Delta().retain(index).retain(length, attributes));
    afterSelection = beforeSelection;
  }

  deleteText(TextNode node, int index, int length) {
    textEdit(node, () => Delta().retain(index).delete(length));
    afterSelection =
        Selection.collapsed(Position(path: node.path, offset: index));
  }

  replaceText(TextNode node, int index, int length, String content,
      [Attributes? attributes]) {
    textEdit(
      node,
      () => Delta().retain(index).delete(length).insert(
            content,
            attributes ??
                node.delta
                    .slice(index, index + length)
                    .operations
                    .first
                    .attributes,
          ),
    );
    afterSelection = Selection.collapsed(
      Position(
        path: node.path,
        offset: index + content.length,
      ),
    );
  }

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
    operations.add(op);
  }

  Transaction finish() {
    return Transaction(
      operations: UnmodifiableListView(operations),
      beforeSelection: beforeSelection,
      afterSelection: afterSelection,
    );
  }
}
