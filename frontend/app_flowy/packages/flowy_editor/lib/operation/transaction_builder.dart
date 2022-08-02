import 'dart:collection';

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
    beforeSelection = state.service.selectionService.currentSelection;
    add(InsertOperation(path: path, value: node));
    // FIXME: Not exactly correct, needs to be customized.
    afterSelection = Selection.collapsed(
      Position(path: path, offset: 0),
    );
  }

  updateNode(Node node, Attributes attributes) {
    beforeSelection = state.cursorSelection;
    add(UpdateOperation(
      path: node.path,
      attributes: Attributes.from(node.attributes)..addAll(attributes),
      oldAttributes: node.attributes,
    ));
  }

  deleteNode(Node node) {
    beforeSelection = state.cursorSelection;
    add(DeleteOperation(path: node.path, removedValue: node));
  }

  deleteNodes(List<Node> nodes) {
    nodes.forEach(deleteNode);
  }

  textEdit(TextNode node, Delta Function() f) {
    beforeSelection = state.service.selectionService.currentSelection;
    final path = node.path;

    final delta = f();

    final inverted = delta.invert(node.delta);

    add(TextEditOperation(path: path, delta: delta, inverted: inverted));
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
    textEdit(node, () => Delta().retain(index).insert(content, attributes));
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

  replaceText(TextNode node, int index, int length, String content) {
    textEdit(
      node,
      () => Delta().retain(index).delete(length).insert(content),
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
          path: op.path,
          delta: last.delta.compose(op.delta),
          inverted: op.inverted.compose(last.inverted),
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
