import 'dart:collection';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flowy_editor/document/attributes.dart';
import 'package:flowy_editor/document/selection.dart';

import './operation.dart';
import './transaction.dart';

///
/// This class is used to
/// build the transaction from the state.
///
/// This class automatically save the
/// cursor from the state.
///
/// When the transaction is undo, the
/// cursor can be restored.
///
class TransactionBuilder {
  final List<Operation> operations = [];
  EditorState state;
  Selection? cursorSelection;

  TransactionBuilder(this.state);

  commit() {
    final transaction = _finish();
    state.apply(transaction);
  }

  void insertNode(Path path, Node node) {
    cursorSelection = state.cursorSelection;
    operations.add(InsertOperation(path: path, value: node));
  }

  void updateNode(Node node, Attributes attributes) {
    cursorSelection = state.cursorSelection;
    operations.add(UpdateOperation(
      path: node.path,
      attributes: Attributes.from(node.attributes)..addAll(attributes),
      oldAttributes: node.attributes,
    ));
  }

  void deleteNode(Node node) {
    cursorSelection = state.cursorSelection;
    operations.add(DeleteOperation(path: node.path, removedValue: node));
  }

  void textEdit(TextNode node, Delta Function() f) {
    cursorSelection = state.cursorSelection;
    final path = node.path;

    final delta = f();

    final inverted = delta.invert(node.delta);
    operations
        .add(TextEditOperation(path: path, delta: delta, inverted: inverted));
  }

  Transaction _finish() {
    return Transaction(
      operations: UnmodifiableListView(operations),
      cursorSelection: cursorSelection,
    );
  }
}
