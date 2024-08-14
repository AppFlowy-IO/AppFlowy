import 'dart:async';
import 'dart:convert';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show
        EditorState,
        Transaction,
        Operation,
        InsertOperation,
        UpdateOperation,
        DeleteOperation,
        PathExtensions,
        Node,
        Path,
        Delta,
        composeAttributes,
        blockComponentDelta;
import 'package:collection/collection.dart';
import 'package:nanoid/nanoid.dart';

const _kExternalTextType = 'text';

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
    final stopwatch = Stopwatch()..start();
    if (enableDocumentInternalLog) {
      Log.debug('transaction => ${transaction.toJson()}');
    }
    final actions = transaction.operations
        .map((op) => op.toBlockAction(editorState, documentId))
        .whereNotNull()
        .expand((element) => element)
        .toList(growable: false); // avoid lazy evaluation
    final textActions = actions.where(
      (e) =>
          e.textDeltaType != TextDeltaType.none && e.textDeltaPayloadPB != null,
    );
    final actionCostTime = stopwatch.elapsedMilliseconds;
    for (final textAction in textActions) {
      final payload = textAction.textDeltaPayloadPB!;
      final type = textAction.textDeltaType;
      if (type == TextDeltaType.create) {
        await documentService.createExternalText(
          documentId: payload.documentId,
          textId: payload.textId,
          delta: payload.delta,
        );
        if (enableDocumentInternalLog) {
          Log.debug(
            '[editor_transaction_adapter] create external text: ${payload.delta}',
          );
        }
      } else if (type == TextDeltaType.update) {
        await documentService.updateExternalText(
          documentId: payload.documentId,
          textId: payload.textId,
          delta: payload.delta,
        );
        if (enableDocumentInternalLog) {
          Log.debug(
            '[editor_transaction_adapter] update external text: ${payload.delta}',
          );
        }
      }
    }
    final blockActions =
        actions.map((e) => e.blockActionPB).toList(growable: false);

    for (final action in blockActions) {
      if (enableDocumentInternalLog) {
        Log.debug(
          '[editor_transaction_adapter] action => ${action.toProto3Json()}',
        );
      }
    }

    await documentService.applyAction(
      documentId: documentId,
      actions: blockActions,
    );
    final elapsed = stopwatch.elapsedMilliseconds;
    stopwatch.stop();
    if (enableDocumentInternalLog) {
      Log.debug(
        '[editor_transaction_adapter] apply transaction cost: total $elapsed ms, converter action $actionCostTime ms, apply action ${elapsed - actionCostTime} ms',
      );
    }
  }
}

extension BlockAction on Operation {
  List<BlockActionWrapper> toBlockAction(
    EditorState editorState,
    String documentId,
  ) {
    final op = this;
    if (op is InsertOperation) {
      return op.toBlockAction(editorState, documentId);
    } else if (op is UpdateOperation) {
      return op.toBlockAction(editorState, documentId);
    } else if (op is DeleteOperation) {
      return op.toBlockAction(editorState);
    }
    throw UnimplementedError();
  }
}

extension on InsertOperation {
  List<BlockActionWrapper> toBlockAction(
    EditorState editorState,
    String documentId, {
    Node? previousNode,
  }) {
    Path currentPath = path;
    final List<BlockActionWrapper> actions = [];
    for (final node in nodes) {
      final parentId = node.parent?.id ??
          editorState.getNodeAtPath(currentPath.parent)?.id ??
          '';
      var prevId = previousNode?.id;
      // if the node is the first child of the parent, then its prevId should be empty.
      final isFirstChild = currentPath.previous.equals(currentPath);
      if (!isFirstChild) {
        prevId ??= editorState.getNodeAtPath(currentPath.previous)?.id ?? '';
      }
      prevId ??= '';
      assert(parentId.isNotEmpty);
      if (isFirstChild) {
        prevId = '';
      } else {
        assert(prevId.isNotEmpty && prevId != node.id);
      }

      // create the external text if the node contains the delta in its data.
      final delta = node.delta;
      TextDeltaPayloadPB? textDeltaPayloadPB;
      String? textId;
      if (delta != null) {
        textId = nanoid(6);

        textDeltaPayloadPB = TextDeltaPayloadPB(
          documentId: documentId,
          textId: textId,
          delta: jsonEncode(node.delta!.toJson()),
        );

        // sync the text id to the node
        node.externalValues = ExternalValues(
          externalId: textId,
          externalType: _kExternalTextType,
        );
      }

      // remove the delta from the data when the incremental update is stable.
      final payload = BlockActionPayloadPB()
        ..block = node.toBlock(
          childrenId: nanoid(6),
          externalId: textId,
          externalType: textId != null ? _kExternalTextType : null,
          attributes: {...node.attributes}..remove(blockComponentDelta),
        )
        ..parentId = parentId
        ..prevId = prevId;

      // pass the external text id to the payload.
      if (textDeltaPayloadPB != null) {
        payload.textId = textDeltaPayloadPB.textId;
      }

      assert(payload.block.childrenId.isNotEmpty);
      final blockActionPB = BlockActionPB()
        ..action = BlockActionTypePB.Insert
        ..payload = payload;

      actions.add(
        BlockActionWrapper(
          blockActionPB: blockActionPB,
          textDeltaPayloadPB: textDeltaPayloadPB,
          textDeltaType: TextDeltaType.create,
        ),
      );
      if (node.children.isNotEmpty) {
        Node? prevChild;
        for (final child in node.children) {
          actions.addAll(
            InsertOperation(currentPath + child.path, [child]).toBlockAction(
              editorState,
              documentId,
              previousNode: prevChild,
            ),
          );
          prevChild = child;
        }
      }
      previousNode = node;
      currentPath = currentPath.next;
    }
    return actions;
  }
}

extension on UpdateOperation {
  List<BlockActionWrapper> toBlockAction(
    EditorState editorState,
    String documentId,
  ) {
    final List<BlockActionWrapper> actions = [];

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

    // create the external text if the node contains the delta in its data.
    final prevDelta = oldAttributes['delta'];
    final delta = attributes['delta'];
    final diff = prevDelta != null && delta != null
        ? Delta.fromJson(prevDelta).diff(
            Delta.fromJson(delta),
          )
        : null;

    final composedAttributes = composeAttributes(oldAttributes, attributes);
    composedAttributes?.remove(blockComponentDelta);

    final payload = BlockActionPayloadPB()
      ..block = node.toBlock(
        parentId: parentId,
        attributes: composedAttributes,
      )
      ..parentId = parentId;
    final blockActionPB = BlockActionPB()
      ..action = BlockActionTypePB.Update
      ..payload = payload;

    final textId = (node.externalValues as ExternalValues?)?.externalId;
    if (textId == null || textId.isEmpty) {
      // to be compatible with the old version, we create a new text id if the text id is empty.
      final textId = nanoid(6);
      final textDeltaPayloadPB = delta == null
          ? null
          : TextDeltaPayloadPB(
              documentId: documentId,
              textId: textId,
              delta: jsonEncode(delta),
            );

      node.externalValues = ExternalValues(
        externalId: textId,
        externalType: _kExternalTextType,
      );

      actions.add(
        BlockActionWrapper(
          blockActionPB: blockActionPB,
          textDeltaPayloadPB: textDeltaPayloadPB,
          textDeltaType: TextDeltaType.create,
        ),
      );
    } else {
      final textDeltaPayloadPB = delta == null
          ? null
          : TextDeltaPayloadPB(
              documentId: documentId,
              textId: textId,
              delta: jsonEncode(diff),
            );

      actions.add(
        BlockActionWrapper(
          blockActionPB: blockActionPB,
          textDeltaPayloadPB: textDeltaPayloadPB,
          textDeltaType: TextDeltaType.update,
        ),
      );
    }

    return actions;
  }
}

extension on DeleteOperation {
  List<BlockActionWrapper> toBlockAction(EditorState editorState) {
    final List<BlockActionPB> actions = [];
    for (final node in nodes) {
      final parentId =
          node.parent?.id ?? editorState.getNodeAtPath(path.parent)?.id ?? '';
      final payload = BlockActionPayloadPB()
        ..block = node.toBlock(
          parentId: parentId,
        )
        ..parentId = parentId;
      assert(parentId.isNotEmpty);
      actions.add(
        BlockActionPB()
          ..action = BlockActionTypePB.Delete
          ..payload = payload,
      );
    }
    return actions
        .map((e) => BlockActionWrapper(blockActionPB: e))
        .toList(growable: false);
  }
}

enum TextDeltaType {
  none,
  create,
  update,
}

class BlockActionWrapper {
  BlockActionWrapper({
    required this.blockActionPB,
    this.textDeltaType = TextDeltaType.none,
    this.textDeltaPayloadPB,
  });

  final BlockActionPB blockActionPB;
  final TextDeltaPayloadPB? textDeltaPayloadPB;
  final TextDeltaType textDeltaType;
}
