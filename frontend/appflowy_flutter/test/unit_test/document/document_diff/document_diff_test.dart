import 'package:appflowy/plugins/document/application/document_diff.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('document diff:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    Node createNodeWithId({required String id, required String text}) {
      return Node(
        id: id,
        type: ParagraphBlockKeys.type,
        attributes: {
          ParagraphBlockKeys.delta: (Delta()..insert(text)).toJson(),
        },
      );
    }

    test('no diff when the document is the same', () async {
      // create two nodes with the same id and texts
      final node1 = createNodeWithId(id: '1', text: 'Hello AppFlowy');
      final node2 = createNodeWithId(id: '1', text: 'Hello AppFlowy');

      final previous = Document.blank()..insert([0], [node1]);
      final next = Document.blank()..insert([0], [node2]);
      final diff = DocumentDiff();
      final operations = diff.diffDocument(previous, next);

      expect(operations, isEmpty);
    });

    test('update text diff with the same id', () {
      final node1 = createNodeWithId(id: '1', text: 'Hello AppFlowy');
      final node2 = createNodeWithId(id: '1', text: 'Hello AppFlowy 2');

      final previous = Document.blank()..insert([0], [node1]);
      final next = Document.blank()..insert([0], [node2]);
      final diff = DocumentDiff();
      final operations = diff.diffDocument(previous, next);

      expect(operations.length, 1);

      final op = operations[0] as UpdateOperation;

      expect(op.path, [0]);
      expect(op.attributes, node2.attributes);
      expect(op.oldAttributes, node1.attributes);
    });
  });
}
