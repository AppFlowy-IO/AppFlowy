import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('image_node_parser.dart', () {
    test('parser image node', () {
      final node = Node(
        type: 'image',
        attributes: {
          'image_src': 'https://appflowy.io',
        },
      );
      final result = const ImageNodeParser().transform(node);
      expect(result, '![](https://appflowy.io)');
    });
  });
}
