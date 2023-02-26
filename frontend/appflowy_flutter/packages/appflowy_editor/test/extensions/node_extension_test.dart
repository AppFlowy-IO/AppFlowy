import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockNode extends Mock implements Node {}

void main() {
  group('NodeExtensions::', () {
    final selection = Selection(
      start: Position(path: [0]),
      end: Position(path: [1]),
    );

    test('inSelection', () {
      // I use an empty implementation instead of mock, because the mocked
      // version throws error trying to access the path.

      final subLinkedList = LinkedList<Node>()
        ..addAll([
          Node(type: 'type', children: LinkedList(), attributes: {}),
          Node(type: 'type', children: LinkedList(), attributes: {}),
          Node(type: 'type', children: LinkedList(), attributes: {}),
          Node(type: 'type', children: LinkedList(), attributes: {}),
          Node(type: 'type', children: LinkedList(), attributes: {}),
        ]);

      final linkedList = LinkedList<Node>()
        ..addAll([
          Node(
            type: 'type',
            children: subLinkedList,
            attributes: {},
          ),
        ]);

      final node = Node(
        type: 'type',
        children: linkedList,
        attributes: {},
      );
      final result = node.inSelection(selection);
      expect(result, false);
    });
  });
}
