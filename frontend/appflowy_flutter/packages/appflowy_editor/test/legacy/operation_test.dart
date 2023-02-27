import 'dart:collection';

import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/src/core/transform/operation.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/core/document/document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('transform path', () {
    test('transform path changed', () {
      expect(transformPath([0, 1], [0, 1]), [0, 2]);
      expect(transformPath([0, 1], [0, 2]), [0, 3]);
      expect(transformPath([0, 1], [0, 2, 7, 8, 9]), [0, 3, 7, 8, 9]);
      expect(transformPath([0, 1, 2], [0, 0, 7, 8, 9]), [0, 0, 7, 8, 9]);
    });
    test("transform path not changed", () {
      expect(transformPath([0, 1, 2], [0, 0, 7, 8, 9]), [0, 0, 7, 8, 9]);
      expect(transformPath([0, 1, 2], [0, 1]), [0, 1]);
      expect(transformPath([1, 1], [1, 0]), [1, 0]);
    });
    test("transform path delta", () {
      expect(transformPath([0, 1], [0, 1], 5), [0, 6]);
    });
  });
  group('transform operation', () {
    test('insert + insert', () {
      final t = transformOperation(
          InsertOperation([0, 1],
              [Node(type: "node", attributes: {}, children: LinkedList())]),
          InsertOperation([0, 1],
              [Node(type: "node", attributes: {}, children: LinkedList())]));
      expect(t.path, [0, 2]);
    });
    test('delete + delete', () {
      final t = transformOperation(
          DeleteOperation([0, 1],
              [Node(type: "node", attributes: {}, children: LinkedList())]),
          DeleteOperation([0, 2],
              [Node(type: "node", attributes: {}, children: LinkedList())]));
      expect(t.path, [0, 1]);
    });
  });
  test('transform transaction builder', () {
    final item1 = Node(type: "node", attributes: {}, children: LinkedList());
    final item2 = Node(type: "node", attributes: {}, children: LinkedList());
    final item3 = Node(type: "node", attributes: {}, children: LinkedList());
    final root = Node(
      type: "root",
      attributes: {},
      children: LinkedList()
        ..addAll([
          item1,
          item2,
          item3,
        ]),
    );
    final state = EditorState(document: Document(root: root));

    expect(item1.path, [0]);
    expect(item2.path, [1]);
    expect(item3.path, [2]);

    final transaction = state.transaction;
    transaction.deleteNode(item1);
    transaction.deleteNode(item2);
    transaction.deleteNode(item3);
    state.apply(transaction);
    expect(transaction.operations[0].path, [0]);
    expect(transaction.operations[1].path, [0]);
    expect(transaction.operations[2].path, [0]);
  });
  group("toJson", () {
    test("insert", () {
      final root = Node(type: "root", attributes: {}, children: LinkedList());
      final state = EditorState(document: Document(root: root));

      final item1 = Node(type: "node", attributes: {}, children: LinkedList());
      final transaction = state.transaction;
      transaction.insertNode([0], item1);
      state.apply(transaction);
      expect(transaction.toJson(), {
        "operations": [
          {
            "op": "insert",
            "path": [0],
            "nodes": [item1.toJson()],
          }
        ]
      });
    });
    test("delete", () {
      final item1 = Node(type: "node", attributes: {}, children: LinkedList());
      final root = Node(
        type: "root",
        attributes: {},
        children: LinkedList()
          ..addAll([
            item1,
          ]),
      );
      final state = EditorState(document: Document(root: root));
      final transaction = state.transaction;
      transaction.deleteNode(item1);
      state.apply(transaction);
      expect(transaction.toJson(), {
        "operations": [
          {
            "op": "delete",
            "path": [0],
            "nodes": [item1.toJson()],
          }
        ],
      });
    });
  });
}
