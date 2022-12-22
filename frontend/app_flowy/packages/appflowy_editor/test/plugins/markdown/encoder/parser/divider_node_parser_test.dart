import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/divider_node_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('divider_node_parser.dart', () {
    test('parser divider node', () {
      final node = Node(
        type: 'divider',
      );
      final result = const DividerNodeParser().transform(node);
      expect(result, '---\n');
    });
  });
}
