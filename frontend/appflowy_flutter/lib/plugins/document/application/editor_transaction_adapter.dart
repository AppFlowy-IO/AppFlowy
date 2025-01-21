import 'dart:async';
import 'dart:convert';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/ask_ai_block_component.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:nanoid/nanoid.dart';

const kExternalTextType = 'text';

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
    if (enableDocumentInternalLog) {
      Log.info(
        '[TransactionAdapter] 2. apply transaction begin ${transaction.hashCode} in $hashCode',
      );
    }

    await _applyInternal(transaction, editorState);

    if (enableDocumentInternalLog) {
      Log.info(
        '[TransactionAdapter] 3. apply transaction end ${transaction.hashCode} in $hashCode',
      );
    }
  }

  Future<void> _applyInternal(
    Transaction transaction,
    EditorState editorState,
  ) async {
    final stopwatch = Stopwatch()..start();
    if (enableDocumentInternalLog) {
      Log.info('transaction => ${transaction.toJson()}');
    }

    final actions = transactionToBlockActions(transaction, editorState);
    final textActions = filterTextDeltaActions(actions);

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
          Log.info(
            '[editor_transaction_adapter] create external text: id: ${payload.textId} delta: ${payload.delta}',
          );
        }
      } else if (type == TextDeltaType.update) {
        await documentService.updateExternalText(
          documentId: payload.documentId,
          textId: payload.textId,
          delta: payload.delta,
        );
        if (enableDocumentInternalLog) {
          Log.info(
            '[editor_transaction_adapter] update external text: id: ${payload.textId} delta: ${payload.delta}',
          );
        }
      }
    }

    final blockActions = filterBlockActions(actions);

    for (final action in blockActions) {
      if (enableDocumentInternalLog) {
        Log.info(
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
      Log.info(
        '[editor_transaction_adapter] apply transaction cost: total $elapsed ms, converter action $actionCostTime ms, apply action ${elapsed - actionCostTime} ms',
      );
    }
  }

  List<BlockActionWrapper> transactionToBlockActions(
    Transaction transaction,
    EditorState editorState,
  ) {
    return transaction.operations
        .map((op) => op.toBlockAction(editorState, documentId))
        .nonNulls
        .expand((element) => element)
        .toList(growable: false); // avoid lazy evaluation
  }

  List<BlockActionWrapper> filterTextDeltaActions(
    List<BlockActionWrapper> actions,
  ) {
    return actions
        .where(
          (e) =>
              e.textDeltaType != TextDeltaType.none &&
              e.textDeltaPayloadPB != null,
        )
        .toList(growable: false);
  }

  List<BlockActionPB> filterBlockActions(
    List<BlockActionWrapper> actions,
  ) {
    return actions.map((e) => e.blockActionPB).toList(growable: false);
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
      if (node.type == AskAIBlockKeys.type) {
        continue;
      }

      final parentId = node.parent?.id ??
          editorState.getNodeAtPath(currentPath.parent)?.id ??
          '';
      assert(parentId.isNotEmpty);

      String prevId = '';
      // if the node is the first child of the parent, then its prevId should be empty.
      final isFirstChild = currentPath.previous.equals(currentPath);

      if (!isFirstChild) {
        prevId = previousNode?.id ??
            editorState.getNodeAtPath(currentPath.previous)?.id ??
            '';
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
          externalType: kExternalTextType,
        );
      }

      // remove the delta from the data when the incremental update is stable.
      final payload = BlockActionPayloadPB()
        ..block = node.toBlock(
          childrenId: nanoid(6),
          externalId: textId,
          externalType: textId != null ? kExternalTextType : null,
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
    final prevDelta = oldAttributes[blockComponentDelta];
    final delta = attributes[blockComponentDelta];

    final composedAttributes = composeAttributes(oldAttributes, attributes);
    final composedDelta = composedAttributes?[blockComponentDelta];
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
      final textDelta = composedDelta ?? delta ?? prevDelta;
      final correctedTextDelta =
          textDelta != null ? _correctAttributes(textDelta) : null;

      final textDeltaPayloadPB = correctedTextDelta == null
          ? null
          : TextDeltaPayloadPB(
              documentId: documentId,
              textId: textId,
              delta: jsonEncode(correctedTextDelta),
            );

      node.externalValues = ExternalValues(
        externalId: textId,
        externalType: kExternalTextType,
      );

      if (enableDocumentInternalLog) {
        Log.info('create text delta: $textDeltaPayloadPB');
      }

      // update the external text id and external type to the block
      blockActionPB.payload.block
        ..externalId = textId
        ..externalType = kExternalTextType;

      actions.add(
        BlockActionWrapper(
          blockActionPB: blockActionPB,
          textDeltaPayloadPB: textDeltaPayloadPB,
          textDeltaType: TextDeltaType.create,
        ),
      );
    } else {
      final diff = prevDelta != null && delta != null
          ? Delta.fromJson(prevDelta).diff(
              Delta.fromJson(delta),
            )
          : null;

      final correctedDiff = diff != null ? _correctDelta(diff) : null;

      final textDeltaPayloadPB = correctedDiff == null
          ? null
          : TextDeltaPayloadPB(
              documentId: documentId,
              textId: textId,
              delta: jsonEncode(correctedDiff),
            );

      if (enableDocumentInternalLog) {
        Log.info('update text delta: $textDeltaPayloadPB');
      }

      // update the external text id and external type to the block
      blockActionPB.payload.block
        ..externalId = textId
        ..externalType = kExternalTextType;

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

  // if the value in Delta's attributes is false, we should set the value to null instead.
  // because on Yjs, canceling format must use the null value. If we use false, the update will be rejected.
  List<TextOperation>? _correctDelta(Delta delta) {
    // if the value in diff's attributes is false, we should set the value to null instead.
    // because on Yjs, canceling format must use the null value. If we use false, the update will be rejected.
    final correctedOps = delta.map((op) {
      final attributes = op.attributes?.map(
        (key, value) => MapEntry(
          key,
          // if the value is false, we should set the value to null instead.
          value == false ? null : value,
        ),
      );

      if (attributes != null) {
        if (op is TextRetain) {
          return TextRetain(op.length, attributes: attributes);
        } else if (op is TextInsert) {
          return TextInsert(op.text, attributes: attributes);
        }
        // ignore the other operations that do not contain attributes.
      }

      return op;
    });

    return correctedOps.toList(growable: false);
  }

  // Refer to [_correctDelta] for more details.
  List<Map<String, dynamic>> _correctAttributes(
    List<Map<String, dynamic>> attributes,
  ) {
    final correctedAttributes = attributes.map((attribute) {
      return attribute.map((key, value) {
        if (value is bool) {
          return MapEntry(key, value == false ? null : value);
        } else if (value is Map<String, dynamic>) {
          return MapEntry(
            key,
            value.map((key, value) {
              return MapEntry(key, value == false ? null : value);
            }),
          );
        }
        return MapEntry(key, value);
      });
    }).toList(growable: false);

    return correctedAttributes;
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
