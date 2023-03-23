import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import '../infra/test_editor.dart';
import 'package:mockito/mockito.dart';

class MockNode extends Mock implements Node {}

void main() {
  group('node_extension.dart', () {
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

    testWidgets('insert a new checkbox after an existing checkbox',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(
          text,
        )
        ..insertTextNode(
          text,
        )
        ..insertTextNode(
          text,
        );
      await editor.startTesting();
      final selection = Selection(
        start: Position(path: [2], offset: 5),
        end: Position(path: [0], offset: 5),
      );
      await editor.updateSelection(selection);
      final nodes =
          editor.editorState.service.selectionService.currentSelectedNodes;
      expect(
        nodes.map((e) => e.path).toList().toString(),
        '[[2], [1], [0]]',
      );
      expect(
        nodes.normalized.map((e) => e.path).toList().toString(),
        '[[0], [1], [2]]',
      );
    });
  });
}
