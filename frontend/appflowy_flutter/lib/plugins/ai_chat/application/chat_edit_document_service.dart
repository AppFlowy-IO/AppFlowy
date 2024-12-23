import 'dart:convert';

import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/plugins/document/application/editor_transaction_adapter.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:nanoid/nanoid.dart';

class ChatEditDocumentService {
  static Future<ViewPB?> saveMessagesToNewPage(
    String parentViewId,
    List<TextMessage> messages,
  ) {
    String completeMessage = '';
    for (final message in messages) {
      completeMessage += '${message.text}\n';
    }
    if (completeMessage.isEmpty) {
      return Future(() => null);
    }
    final document = customMarkdownToDocument(completeMessage);
    final initialBytes =
        DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
    return initialBytes != null
        ? ViewBackendService.createView(
            name: '',
            layoutType: ViewLayoutPB.Document,
            parentViewId: parentViewId,
            initialDataBytes:
                DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer(),
            // TODO: Consider the location of this document?
          ).toNullable()
        : Future(() => null);
  }

  static void addMessageToPage(
    String documentId,
    TextMessage message,
  ) async {
    final documentPB = await DocumentService()
        .getDocument(documentId: documentId)
        .toNullable();
    final document = documentPB?.toDocument();
    if (document == null) {
      return;
    }

    final lastNodeOrNull = document.root.children.lastOrNull;

    final messageDocument = customMarkdownToDocument(message.text);
    final rootIsEmpty = lastNodeOrNull == null;
    final isLastLineEmpty = _isLastLineEmpty(lastNodeOrNull);

    final nodes = [
      if (rootIsEmpty || !isLastLineEmpty) paragraphNode(),
      ...messageDocument.root.children,
    ];

    final insertPath = rootIsEmpty ? [0] : lastNodeOrNull.path.next;

    document.insert(insertPath, nodes);

    final actions = _insertOperationToBlockActions(
      document,
      documentId,
      InsertOperation(insertPath, nodes),
      lastNodeOrNull,
    );

    final documentService = DocumentService();

    final textActions = filterTextDeltaActions(actions);
    final blockActions = filterBlockActions(actions);

    for (final textAction in textActions) {
      final payload = textAction.textDeltaPayloadPB!;
      final type = textAction.textDeltaType;

      if (type == TextDeltaType.create) {
        await documentService.createExternalText(
          documentId: payload.documentId,
          textId: payload.textId,
          delta: payload.delta,
        );
      }
    }

    await documentService.applyAction(
      documentId: documentId,
      actions: blockActions,
    );
  }

  static bool _isLastLineEmpty(Node? lastNode) {
    if (lastNode == null) {
      return true;
    }
    final delta = lastNode.delta;

    return delta != null && (delta.isEmpty || delta.toPlainText().isEmpty);
  }

  static List<BlockActionWrapper> _insertOperationToBlockActions(
    Document document,
    String documentId,
    InsertOperation operation,
    Node? previousNode,
  ) {
    Path currentPath = [...operation.path];
    final List<BlockActionWrapper> actions = [];
    for (final node in operation.nodes) {
      if (node.type == AskAIBlockKeys.type) {
        continue;
      }

      final parentId =
          node.parent?.id ?? document.nodeAtPath(currentPath.parent)?.id ?? '';
      String prevId = '';
      // if the node is the first child of the parent, then its prevId should be empty.
      final isFirstChild = currentPath.previous.equals(currentPath);

      if (!isFirstChild) {
        prevId = previousNode?.id ??
            document.nodeAtPath(currentPath.previous)?.id ??
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
            _insertOperationToBlockActions(
              document,
              documentId,
              InsertOperation(currentPath + child.path, [child]),
              prevChild,
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
