import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/infra/infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('infra.dart', () {
    test('find the last text node', () {
      // * Welcome to Appflowy 😁
      //  * Welcome to Appflowy 😁
      //  * Welcome to Appflowy 😁
      //    * Welcome to Appflowy 😁
      //    * Welcome to Appflowy 😁
      //      * Welcome to Appflowy 😁
      //      * Welcome to Appflowy 😁
      const text = 'Welcome to Appflowy 😁';
      TextNode textNode() {
        return TextNode(
          delta: Delta()..insert(text),
        );
      }

      final node110 = textNode();
      final node111 = textNode();
      final node11 = textNode()
        ..insert(node110)
        ..insert(node111);
      final node10 = textNode();
      final node1 = textNode()
        ..insert(node10)
        ..insert(node11);
      final node0 = textNode();
      final node = textNode()
        ..insert(node0)
        ..insert(node1);

      expect(Infra.findLastTextNode(node)?.path, [1, 1, 1]);
      expect(Infra.findLastTextNode(node0)?.path, [0]);
      expect(Infra.findLastTextNode(node1)?.path, [1, 1, 1]);
      expect(Infra.findLastTextNode(node10)?.path, [1, 0]);
      expect(Infra.findLastTextNode(node11)?.path, [1, 1, 1]);

      expect(Infra.forwardNearestTextNode(node111)?.path, [1, 1, 0]);
      expect(Infra.forwardNearestTextNode(node110)?.path, [1, 1]);
      expect(Infra.forwardNearestTextNode(node11)?.path, [1, 0]);
      expect(Infra.forwardNearestTextNode(node10)?.path, [1]);
      expect(Infra.forwardNearestTextNode(node1)?.path, [0]);
      expect(Infra.forwardNearestTextNode(node0)?.path, []);
    });
  });
}
