import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/core/document/node_iterator.dart';
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
        stateTree: StateTree(root: root),
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
  });
}
