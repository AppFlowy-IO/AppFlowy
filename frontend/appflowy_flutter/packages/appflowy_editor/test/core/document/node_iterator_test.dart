import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('node_iterator.dart', () {
    test('', () {
      final root = Node(type: 'root');
      for (var i = 1; i <= 10; i++) {
        final node = Node(type: 'node_$i');
        for (var j = 1; j <= i; j++) {
          node.insert(Node(type: 'node_${i}_$j'));
        }
        root.insert(node);
      }
      final nodes = NodeIterator(
        document: Document(root: root),
        startNode: root.childAtPath([0])!,
        endNode: root.childAtPath([10, 10]),
      );

      for (var i = 1; i <= 10; i++) {
        nodes.moveNext();
        expect(nodes.current.type, 'node_$i');
        for (var j = 1; j <= i; j++) {
          nodes.moveNext();
          expect(nodes.current.type, 'node_${i}_$j');
        }
      }
      expect(nodes.moveNext(), false);
    });

    test('toList - when we have at least three level nested nodes (children)',
        () {
      final root = Node(type: 'root'),
          n1 = Node(type: 'node_1'),
          n2 = Node(type: 'node_2');

      root.insert(n1);
      root.insert(n2);
      n1.insert(Node(type: 'node_1_1'));
      n1.insert(Node(type: 'node_1_2'));
      n1.childAtIndex(0)?.insert(Node(type: 'node_1_1_1'));
      n1.childAtIndex(1)?.insert(Node(type: 'node_1_2_1'));

      final nodes = NodeIterator(
        document: Document(root: root),
        startNode: root.childAtPath([0])!,
        endNode: root.childAtPath([1]),
      ).toList();

      expect(nodes[0].id, n1.id);
      expect(nodes[1].id, n1.childAtIndex(0)!.id);
      expect(nodes[nodes.length - 1].id, n2.id);
    });
  });
}
