import 'dart:collection';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/undo_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Node _createEmptyEditorRoot() {
    return Node(
      type: 'editor',
      children: LinkedList(),
      attributes: {},
    );
  }

  test("HistoryItem #1", () {
    final document = Document(root: _createEmptyEditorRoot());
    final editorState = EditorState(document: document);

    final historyItem = HistoryItem();
    historyItem
        .add(DeleteOperation([0], [TextNode(delta: Delta()..insert('0'))]));
    historyItem
        .add(DeleteOperation([0], [TextNode(delta: Delta()..insert('1'))]));
    historyItem
        .add(DeleteOperation([0], [TextNode(delta: Delta()..insert('2'))]));

    final transaction = historyItem.toTransaction(editorState);
    assert(isInsertAndPathEqual(transaction.operations[0], [0], '2'));
    assert(isInsertAndPathEqual(transaction.operations[1], [0], '1'));
    assert(isInsertAndPathEqual(transaction.operations[2], [0], '0'));
  });

  test("HistoryItem #2", () {
    final document = Document(root: _createEmptyEditorRoot());
    final editorState = EditorState(document: document);

    final historyItem = HistoryItem();
    historyItem
        .add(DeleteOperation([0], [TextNode(delta: Delta()..insert('0'))]));
    historyItem
        .add(UpdateOperation([0], {"subType": "number"}, {"subType": null}));
    historyItem.add(DeleteOperation([0], [TextNode.empty(), TextNode.empty()]));
    historyItem.add(DeleteOperation([0], [TextNode.empty()]));

    final transaction = historyItem.toTransaction(editorState);
    assert(isInsertAndPathEqual(transaction.operations[0], [0]));
    assert(isInsertAndPathEqual(transaction.operations[1], [0]));
    assert(transaction.operations[2] is UpdateOperation);
    assert(isInsertAndPathEqual(transaction.operations[3], [0], '0'));
  });
}

bool isInsertAndPathEqual(Operation operation, Path path, [String? content]) {
  if (operation is! InsertOperation) {
    return false;
  }

  if (!operation.path.equals(path)) {
    return false;
  }

  final firstNode = operation.nodes[0];
  if (firstNode is! TextNode) {
    return false;
  }

  if (content == null) {
    return true;
  }

  return firstNode.delta.toPlainText() == content;
}
