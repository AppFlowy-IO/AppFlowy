import 'dart:async';

import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/plugins/document/application/editor_transaction_adapter.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionAdapter:', () {
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

    test('update the external id and external type', () async {
      // create a node without external id and external type
      // the editing this node, the adapter should generate a new action
      //  to assign a new external id and external type.
      final node = bulletedListNode(text: 'Hello');
      final document = Document(
        root: pageNode(
          children: [
            node,
          ],
        ),
      );

      final transactionAdapter = TransactionAdapter(
        documentId: '',
        documentService: DocumentService(),
      );

      final editorState = EditorState(
        document: document,
      );

      final completer = Completer();
      editorState.transactionStream.listen((event) {
        final time = event.$1;
        if (time == TransactionTime.before) {
          final actions = transactionAdapter.transactionToBlockActions(
            event.$2,
            editorState,
          );
          final textActions =
              transactionAdapter.filterTextDeltaActions(actions);
          final blockActions = transactionAdapter.filterBlockActions(actions);
          expect(textActions.length, 1);
          expect(blockActions.length, 1);

          // check text operation
          final textAction = textActions.first;
          final textId = textAction.textDeltaPayloadPB?.textId;
          {
            expect(textAction.textDeltaType, TextDeltaType.create);

            expect(textId, isNotEmpty);
            final delta = textAction.textDeltaPayloadPB?.delta;
            expect(delta, equals('[{"insert":"HelloWorld"}]'));
          }

          // check block operation
          {
            final blockAction = blockActions.first;
            expect(blockAction.action, BlockActionTypePB.Update);
            expect(blockAction.payload.block.id, node.id);
            expect(
              blockAction.payload.block.externalId,
              textId,
            );
            expect(blockAction.payload.block.externalType, kExternalTextType);
          }
        } else if (time == TransactionTime.after) {
          completer.complete();
        }
      });

      await editorState.insertText(
        5,
        'World',
        node: node,
      );
      await completer.future;
    });

    test('use delta from prev attributes if current delta is null', () async {
      final node = todoListNode(
        checked: false,
        delta: Delta()..insert('AppFlowy'),
      );
      final document = Document(
        root: pageNode(
          children: [
            node,
          ],
        ),
      );
      final transactionAdapter = TransactionAdapter(
        documentId: '',
        documentService: DocumentService(),
      );

      final editorState = EditorState(
        document: document,
      );

      final completer = Completer();
      editorState.transactionStream.listen((event) {
        final time = event.$1;
        if (time == TransactionTime.before) {
          final actions = transactionAdapter.transactionToBlockActions(
            event.$2,
            editorState,
          );
          final textActions =
              transactionAdapter.filterTextDeltaActions(actions);
          final blockActions = transactionAdapter.filterBlockActions(actions);
          expect(textActions.length, 1);
          expect(blockActions.length, 1);

          // check text operation
          final textAction = textActions.first;
          final textId = textAction.textDeltaPayloadPB?.textId;
          {
            expect(textAction.textDeltaType, TextDeltaType.create);

            expect(textId, isNotEmpty);
            final delta = textAction.textDeltaPayloadPB?.delta;
            expect(delta, equals('[{"insert":"AppFlowy"}]'));
          }

          // check block operation
          {
            final blockAction = blockActions.first;
            expect(blockAction.action, BlockActionTypePB.Update);
            expect(blockAction.payload.block.id, node.id);
            expect(
              blockAction.payload.block.externalId,
              textId,
            );
            expect(blockAction.payload.block.externalType, kExternalTextType);
          }
        } else if (time == TransactionTime.after) {
          completer.complete();
        }
      });

      final transaction = editorState.transaction;
      transaction.updateNode(node, {TodoListBlockKeys.checked: true});
      await editorState.apply(transaction);
      await completer.future;
    });

    test('text retain with attributes that are false', () async {
      final node = paragraphNode(
        delta: Delta()
          ..insert(
            'Hello AppFlowy',
            attributes: {
              'bold': true,
            },
          ),
      );
      final document = Document(
        root: pageNode(
          children: [
            node,
          ],
        ),
      );
      final transactionAdapter = TransactionAdapter(
        documentId: '',
        documentService: DocumentService(),
      );

      final editorState = EditorState(
        document: document,
      );

      int counter = 0;
      final completer = Completer();
      editorState.transactionStream.listen((event) {
        final time = event.$1;
        if (time == TransactionTime.before) {
          final actions = transactionAdapter.transactionToBlockActions(
            event.$2,
            editorState,
          );
          final textActions =
              transactionAdapter.filterTextDeltaActions(actions);
          final blockActions = transactionAdapter.filterBlockActions(actions);
          expect(textActions.length, 1);
          expect(blockActions.length, 1);
          if (counter == 1) {
            // check text operation
            final textAction = textActions.first;
            final textId = textAction.textDeltaPayloadPB?.textId;
            {
              expect(textAction.textDeltaType, TextDeltaType.create);

              expect(textId, isNotEmpty);
              final delta = textAction.textDeltaPayloadPB?.delta;
              expect(
                delta,
                equals(
                  '[{"insert":"Hello","attributes":{"bold":null}},{"insert":" AppFlowy","attributes":{"bold":true}}]',
                ),
              );
            }
          } else if (counter == 3) {
            final textAction = textActions.first;
            final textId = textAction.textDeltaPayloadPB?.textId;
            {
              expect(textAction.textDeltaType, TextDeltaType.update);

              expect(textId, isNotEmpty);
              final delta = textAction.textDeltaPayloadPB?.delta;
              expect(
                delta,
                equals(
                  '[{"retain":5,"attributes":{"bold":null}}]',
                ),
              );
            }
          }
        } else if (time == TransactionTime.after && counter == 3) {
          completer.complete();
        }
      });

      counter = 1;
      final insertTransaction = editorState.transaction;
      insertTransaction.formatText(node, 0, 5, {
        'bold': false,
      });

      await editorState.apply(insertTransaction);

      counter = 2;
      final updateTransaction = editorState.transaction;
      updateTransaction.formatText(node, 0, 5, {
        'bold': true,
      });
      await editorState.apply(updateTransaction);

      counter = 3;
      final formatTransaction = editorState.transaction;
      formatTransaction.formatText(node, 0, 5, {
        'bold': false,
      });
      await editorState.apply(formatTransaction);

      await completer.future;
    });
  });
}
