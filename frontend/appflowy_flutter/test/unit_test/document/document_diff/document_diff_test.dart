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

    final diff = DocumentDiff();

    Node createNodeWithId({required String id, required String text}) {
      return Node(
        id: id,
        type: ParagraphBlockKeys.type,
        attributes: {
          ParagraphBlockKeys.delta: (Delta()..insert(text)).toJson(),
        },
      );
    }

    Future<void> applyOperationAndVerifyDocument(
      Document before,
      Document after,
      List<Operation> operations,
    ) async {
      final expected = after.toJson();
      final editorState = EditorState(document: before);
      final transaction = editorState.transaction;
      for (final operation in operations) {
        transaction.add(operation);
      }
      await editorState.apply(transaction);
      expect(editorState.document.toJson(), expected);
    }

    test('no diff when the document is the same', () async {
      // create two nodes with the same id and texts
      final node1 = createNodeWithId(id: '1', text: 'Hello AppFlowy');
      final node2 = createNodeWithId(id: '1', text: 'Hello AppFlowy');

      final previous = Document.blank()..insert([0], [node1]);
      final next = Document.blank()..insert([0], [node2]);
      final operations = diff.diffDocument(previous, next);

      expect(operations, isEmpty);

      await applyOperationAndVerifyDocument(previous, next, operations);
    });

    test('update text diff with the same id', () async {
      final node1 = createNodeWithId(id: '1', text: 'Hello AppFlowy');
      final node2 = createNodeWithId(id: '1', text: 'Hello AppFlowy 2');

      final previous = Document.blank()..insert([0], [node1]);
      final next = Document.blank()..insert([0], [node2]);
      final operations = diff.diffDocument(previous, next);

      expect(operations.length, 1);
      expect(operations[0], isA<UpdateOperation>());

      await applyOperationAndVerifyDocument(previous, next, operations);
    });

    test('delete and insert text diff with different id', () async {
      final node1 = createNodeWithId(id: '1', text: 'Hello AppFlowy');
      final node2 = createNodeWithId(id: '2', text: 'Hello AppFlowy 2');

      final previous = Document.blank()..insert([0], [node1]);
      final next = Document.blank()..insert([0], [node2]);

      final operations = diff.diffDocument(previous, next);

      expect(operations.length, 2);
      expect(operations[0], isA<InsertOperation>());
      expect(operations[1], isA<DeleteOperation>());

      await applyOperationAndVerifyDocument(previous, next, operations);
    });

    test('insert single text diff', () async {
      final node1 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node21 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node22 = createNodeWithId(
        id: '2',
        text: 'Hello AppFlowy - Second line',
      );

      final previous = Document.blank()..insert([0], [node1]);
      final next = Document.blank()..insert([0], [node21, node22]);

      final operations = diff.diffDocument(previous, next);

      expect(operations.length, 1);
      expect(operations[0], isA<InsertOperation>());

      await applyOperationAndVerifyDocument(previous, next, operations);
    });

    test('delete single text diff', () async {
      final node11 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node12 = createNodeWithId(
        id: '2',
        text: 'Hello AppFlowy - Second line',
      );
      final node21 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );

      final previous = Document.blank()..insert([0], [node11, node12]);
      final next = Document.blank()..insert([0], [node21]);

      final operations = diff.diffDocument(previous, next);

      expect(operations.length, 1);
      expect(operations[0], isA<DeleteOperation>());

      await applyOperationAndVerifyDocument(previous, next, operations);
    });

    test('insert multiple texts diff', () async {
      final node11 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node15 = createNodeWithId(
        id: '5',
        text: 'Hello AppFlowy - Fifth line',
      );
      final node21 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node22 = createNodeWithId(
        id: '2',
        text: 'Hello AppFlowy - Second line',
      );
      final node23 = createNodeWithId(
        id: '3',
        text: 'Hello AppFlowy - Third line',
      );
      final node24 = createNodeWithId(
        id: '4',
        text: 'Hello AppFlowy - Fourth line',
      );
      final node25 = createNodeWithId(
        id: '5',
        text: 'Hello AppFlowy - Fifth line',
      );

      final previous = Document.blank()
        ..insert(
          [0],
          [
            node11,
            node15,
          ],
        );
      final next = Document.blank()
        ..insert(
          [0],
          [
            node21,
            node22,
            node23,
            node24,
            node25,
          ],
        );

      final operations = diff.diffDocument(previous, next);

      expect(operations.length, 1);

      final op = operations[0] as InsertOperation;
      expect(op.path, [1]);
      expect(op.nodes, [node22, node23, node24]);

      await applyOperationAndVerifyDocument(previous, next, operations);
    });

    test('delete multiple texts diff', () async {
      final node11 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node12 = createNodeWithId(
        id: '2',
        text: 'Hello AppFlowy - Second line',
      );
      final node13 = createNodeWithId(
        id: '3',
        text: 'Hello AppFlowy - Third line',
      );
      final node14 = createNodeWithId(
        id: '4',
        text: 'Hello AppFlowy - Fourth line',
      );
      final node15 = createNodeWithId(
        id: '5',
        text: 'Hello AppFlowy - Fifth line',
      );

      final node21 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node25 = createNodeWithId(
        id: '5',
        text: 'Hello AppFlowy - Fifth line',
      );

      final previous = Document.blank()
        ..insert(
          [0],
          [
            node11,
            node12,
            node13,
            node14,
            node15,
          ],
        );
      final next = Document.blank()
        ..insert(
          [0],
          [
            node21,
            node25,
          ],
        );

      final operations = diff.diffDocument(previous, next);

      expect(operations.length, 1);

      final op = operations[0] as DeleteOperation;
      expect(op.path, [1]);
      expect(op.nodes, [node12, node13, node14]);

      await applyOperationAndVerifyDocument(previous, next, operations);
    });

    test('multiple delete and update diff', () async {
      final node11 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node12 = createNodeWithId(
        id: '2',
        text: 'Hello AppFlowy - Second line',
      );
      final node13 = createNodeWithId(
        id: '3',
        text: 'Hello AppFlowy - Third line',
      );
      final node14 = createNodeWithId(
        id: '4',
        text: 'Hello AppFlowy - Fourth line',
      );
      final node15 = createNodeWithId(
        id: '5',
        text: 'Hello AppFlowy - Fifth line',
      );

      final node21 = createNodeWithId(
        id: '1',
        text: 'Hello AppFlowy - First line',
      );
      final node22 = createNodeWithId(
        id: '2',
        text: '',
      );
      final node25 = createNodeWithId(
        id: '5',
        text: 'Hello AppFlowy - Fifth line',
      );

      final previous = Document.blank()
        ..insert(
          [0],
          [
            node11,
            node12,
            node13,
            node14,
            node15,
          ],
        );
      final next = Document.blank()
        ..insert(
          [0],
          [
            node21,
            node22,
            node25,
          ],
        );

      final operations = diff.diffDocument(previous, next);

      expect(operations.length, 2);
      final op1 = operations[0] as UpdateOperation;
      expect(op1.path, [1]);
      expect(op1.attributes, node22.attributes);

      final op2 = operations[1] as DeleteOperation;
      expect(op2.path, [2]);
      expect(op2.nodes, [node13, node14]);

      await applyOperationAndVerifyDocument(previous, next, operations);
    });
  });
}
