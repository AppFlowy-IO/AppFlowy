import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('documemnt.dart', () {
    test('insert', () {
      final document = Document.empty();

      expect(document.insert([-1], []), false);
      expect(document.insert([100], []), false);

      final node0 = Node(type: '0');
      final node1 = Node(type: '1');
      expect(document.insert([0], [node0, node1]), true);
      expect(document.nodeAtPath([0])?.type, '0');
      expect(document.nodeAtPath([1])?.type, '1');
    });

    test('delete', () {
      final document = Document(root: Node(type: 'root'));

      expect(document.delete([-1], 1), false);
      expect(document.delete([100], 1), false);

      for (var i = 0; i < 10; i++) {
        final node = Node(type: '$i');
        document.insert([i], [node]);
      }

      document.delete([0], 10);
      expect(document.root.children.isEmpty, true);
    });

    test('update', () {
      final node = Node(type: 'example', attributes: {'a': 'a'});
      final document = Document(root: Node(type: 'root'));
      document.insert([0], [node]);

      final attributes = {
        'a': 'b',
        'b': 'c',
      };

      expect(document.update([0], attributes), true);
      expect(document.nodeAtPath([0])?.attributes, attributes);

      expect(document.update([-1], attributes), false);
    });

    test('updateText', () {
      final delta = Delta()..insert('Editor');
      final textNode = TextNode(delta: delta);
      final document = Document(root: Node(type: 'root'));
      document.insert([0], [textNode]);
      document.updateText([0], Delta()..insert('AppFlowy'));
      expect((document.nodeAtPath([0]) as TextNode).toPlainText(),
          'AppFlowyEditor');
    });

    test('serialize', () {
      final json = {
        'document': {
          'type': 'editor',
          'children': [
            {
              'type': 'text',
              'delta': [],
            }
          ],
          'attributes': {'a': 'a'}
        }
      };
      final document = Document.fromJson(json);
      expect(document.toJson(), json);
    });
  });
}
