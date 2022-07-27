import 'dart:collection';

import 'package:flowy_editor/document/node.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_editor/operation/operation.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/document/state_tree.dart';
import 'package:flowy_editor/render/render_plugins.dart';

void main() {
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
    });
    test("transform path delta", () {
      expect(transformPath([0, 1], [0, 1], 5), [0, 6]);
    });
  });
  group('transform operation', () {
    test('insert + insert', () {
      final t = transformOperation(
          InsertOperation(path: [
            0,
            1
          ], value: Node(type: "node", attributes: {}, children: LinkedList())),
          InsertOperation(
              path: [0, 1],
              value:
                  Node(type: "node", attributes: {}, children: LinkedList())));
      expect(t.path, [0, 2]);
    });
    test('delete + delete', () {
      final t = transformOperation(
          DeleteOperation(
              path: [0, 1],
              removedValue:
                  Node(type: "node", attributes: {}, children: LinkedList())),
          DeleteOperation(
              path: [0, 2],
              removedValue:
                  Node(type: "node", attributes: {}, children: LinkedList())));
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
          ]));
    final state = EditorState(
        document: StateTree(root: root), renderPlugins: RenderPlugins());

    expect(item1.path, [0]);
    expect(item2.path, [1]);
    expect(item3.path, [2]);

    final tb = TransactionBuilder(state);
    tb.deleteNode(item1);
    tb.deleteNode(item2);
    tb.deleteNode(item3);
    final transaction = tb.finish();
    expect(transaction.operations[0].path, [0]);
    expect(transaction.operations[1].path, [0]);
    expect(transaction.operations[2].path, [0]);
  });
}
