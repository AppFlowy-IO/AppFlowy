import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/doc_service.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show
        EditorState,
        Transaction,
        Operation,
        InsertOperation,
        UpdateOperation,
        DeleteOperation,
        PathExtensions,
        Node;
import 'package:collection/collection.dart';
import 'dart:async';

import 'package:nanoid/nanoid.dart';

/// Uses to adjust the data structure between the editor and the backend.
///
/// The editor uses a tree structure to represent the document, while the backend uses a flat structure.
/// This adapter is used to convert the editor's transaction to the backend's transaction.
class TransactionAdapter {
  TransactionAdapter({
    required this.documentId,
    required this.documentService,
  });

  final DocumentService documentService;
  final String documentId;

  Future<void> apply(Transaction transaction, EditorState editorState) async {
    // Log.debug('transaction => ${transaction.toJson()}');
    final actions = transaction.operations
        .map((op) => op.toBlockAction(editorState))
        .whereNotNull()
        .expand((element) => element);
    // Log.debug('actions => $actions');
    await documentService.applyAction(
      documentId: documentId,
      actions: actions,
    );
  }
}

extension on Operation {
  List<BlockActionPB> toBlockAction(EditorState editorState) {
    final op = this;
    if (op is InsertOperation) {
      return op.toBlockAction(editorState);
    } else if (op is UpdateOperation) {
      return op.toBlockAction(editorState);
    } else if (op is DeleteOperation) {
      return op.toBlockAction(editorState);
    }
    throw UnimplementedError();
  }
}

extension on InsertOperation {
  List<BlockActionPB> toBlockAction(EditorState editorState) {
    final List<BlockActionPB> actions = [];
    // store the previous node for continuous insertion.
    // because the backend needs to know the previous node's id.
    Node? previousNode;
    for (final node in nodes) {
      final parentId =
          node.parent?.id ?? editorState.getNodeAtPath(path.parent)?.id ?? '';
      var prevId = previousNode?.id ??
          editorState.getNodeAtPath(path.previous)?.id ??
          '';
      assert(parentId.isNotEmpty);
      if (path.equals(path.previous)) {
        prevId = '';
      } else {
        assert(prevId.isNotEmpty && prevId != node.id);
      }
      final payload = BlockActionPayloadPB()
        ..block = node.toBlock(childrenId: nanoid(10))
        ..parentId = parentId
        ..prevId = prevId;
      assert(payload.block.childrenId.isNotEmpty);
      actions.add(
        BlockActionPB()
          ..action = BlockActionTypePB.Insert
          ..payload = payload,
      );
      if (node.children.isNotEmpty) {
        final childrenActions = node.children
            .map((e) => InsertOperation(e.path, [e]).toBlockAction(editorState))
            .expand((element) => element);
        actions.addAll(childrenActions);
      }
      previousNode = node;
    }
    return actions;
  }
}

extension on UpdateOperation {
  List<BlockActionPB> toBlockAction(EditorState editorState) {
    final List<BlockActionPB> actions = [];

    // if the attributes are both empty, we don't need to update
    if (const DeepCollectionEquality().equals(attributes, oldAttributes)) {
      return actions;
    }
    final node = editorState.getNodeAtPath(path);
    if (node == null) {
      assert(false, 'node not found at path: $path');
      return actions;
    }
    final parentId =
        node.parent?.id ?? editorState.getNodeAtPath(path.parent)?.id ?? '';
    assert(parentId.isNotEmpty);
    final payload = BlockActionPayloadPB()
      ..block = node.toBlock()
      ..parentId = parentId;
    actions.add(
      BlockActionPB()
        ..action = BlockActionTypePB.Update
        ..payload = payload,
    );
    return actions;
  }
}

extension on DeleteOperation {
  List<BlockActionPB> toBlockAction(EditorState editorState) {
    final List<BlockActionPB> actions = [];
    for (final node in nodes) {
      final parentId =
          node.parent?.id ?? editorState.getNodeAtPath(path.parent)?.id ?? '';
      final payload = BlockActionPayloadPB()
        ..block = node.toBlock()
        ..parentId = parentId;
      assert(parentId.isNotEmpty);
      actions.add(
        BlockActionPB()
          ..action = BlockActionTypePB.Delete
          ..payload = payload,
      );
    }
    return actions;
  }
}
