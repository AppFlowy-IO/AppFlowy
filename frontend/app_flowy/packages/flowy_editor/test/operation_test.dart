import 'dart:collection';

import 'package:flowy_editor/document/node.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_editor/operation/operation.dart';

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
}
