import 'package:appflowy/plugins/document/application/editor_transaction_adapter.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionAdapter', () {
    test('toBlockAction insert node with children operation', () {
      final editorState = EditorState.blank();

      final transaction = editorState.transaction;
      transaction.insertNode(
        [0],
        paragraphNode(
          children: [
            paragraphNode(text: '1', children: [paragraphNode(text: '1.1')]),
            paragraphNode(text: '2'),
            paragraphNode(text: '3', children: [paragraphNode(text: '3.1')]),
            paragraphNode(text: '4'),
          ],
        ),
      );

      expect(transaction.operations.length, 1);
      expect(transaction.operations[0] is InsertOperation, true);

      final actions = transaction.operations[0].toBlockAction(editorState, '');

      expect(actions.length, 7);
      for (final action in actions) {
        expect(action.blockActionPB.action, BlockActionTypePB.Insert);
      }

      expect(
        actions[0].blockActionPB.payload.parentId,
        editorState.document.root.id,
        reason: '0 - parent id',
      );
      expect(
        actions[0].blockActionPB.payload.prevId,
        '',
        reason: '0 - prev id',
      );
      expect(
        actions[1].blockActionPB.payload.parentId,
        actions[0].blockActionPB.payload.block.id,
        reason: '1 - parent id',
      );
      expect(
        actions[1].blockActionPB.payload.prevId,
        '',
        reason: '1 - prev id',
      );
      expect(
        actions[2].blockActionPB.payload.parentId,
        actions[1].blockActionPB.payload.block.id,
        reason: '2 - parent id',
      );
      expect(
        actions[2].blockActionPB.payload.prevId,
        '',
        reason: '2 - prev id',
      );
      expect(
        actions[3].blockActionPB.payload.parentId,
        actions[0].blockActionPB.payload.block.id,
        reason: '3 - parent id',
      );
      expect(
        actions[3].blockActionPB.payload.prevId,
        actions[1].blockActionPB.payload.block.id,
        reason: '3 - prev id',
      );
      expect(
        actions[4].blockActionPB.payload.parentId,
        actions[0].blockActionPB.payload.block.id,
        reason: '4 - parent id',
      );
      expect(
        actions[4].blockActionPB.payload.prevId,
        actions[3].blockActionPB.payload.block.id,
        reason: '4 - prev id',
      );
      expect(
        actions[5].blockActionPB.payload.parentId,
        actions[4].blockActionPB.payload.block.id,
        reason: '5 - parent id',
      );
      expect(
        actions[5].blockActionPB.payload.prevId,
        '',
        reason: '5 - prev id',
      );
      expect(
        actions[6].blockActionPB.payload.parentId,
        actions[0].blockActionPB.payload.block.id,
        reason: '6 - parent id',
      );
      expect(
        actions[6].blockActionPB.payload.prevId,
        actions[4].blockActionPB.payload.block.id,
        reason: '6 - prev id',
      );
    });

    test('toBlockAction insert node before all children nodes', () {
      final document = Document(
        root: Node(
          type: 'page',
          children: [
            paragraphNode(children: [paragraphNode(text: '1')]),
          ],
        ),
      );
      final editorState = EditorState(document: document);

      final transaction = editorState.transaction;
      transaction.insertNodes([0, 0], [paragraphNode(), paragraphNode()]);

      expect(transaction.operations.length, 1);
      expect(transaction.operations[0] is InsertOperation, true);

      final actions = transaction.operations[0].toBlockAction(editorState, '');

      expect(actions.length, 2);
      for (final action in actions) {
        expect(action.blockActionPB.action, BlockActionTypePB.Insert);
      }

      expect(
        actions[0].blockActionPB.payload.parentId,
        editorState.document.root.children.first.id,
        reason: '0 - parent id',
      );
      expect(
        actions[0].blockActionPB.payload.prevId,
        '',
        reason: '0 - prev id',
      );
      expect(
        actions[1].blockActionPB.payload.parentId,
        editorState.document.root.children.first.id,
        reason: '1 - parent id',
      );
      expect(
        actions[1].blockActionPB.payload.prevId,
        actions[0].blockActionPB.payload.block.id,
        reason: '1 - prev id',
      );
    });
  });
}
