import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

class ChatEditDocumentService {
  static Future<ViewPB?> saveMessagesToNewPage(
    String chatPageName,
    String parentViewId,
    List<TextMessage> messages,
  ) async {
    if (messages.isEmpty) {
      return null;
    }

    // Convert messages to markdown and trim the last empty newline.
    final completeMessage = messages.map((m) => m.text).join('\n').trimRight();
    if (completeMessage.isEmpty) {
      return null;
    }

    final document = customMarkdownToDocument(completeMessage);
    final initialBytes =
        DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
    if (initialBytes == null) {
      Log.error('Failed to convert messages to document');
      return null;
    }

    return ViewBackendService.createView(
      name: LocaleKeys.chat_addToNewPageName.tr(args: [chatPageName]),
      layoutType: ViewLayoutPB.Document,
      parentViewId: parentViewId,
      initialDataBytes: initialBytes,
    ).toNullable();
  }

  static Future<void> addMessageToPage(
    String documentId,
    TextMessage message,
  ) async {
    if (message.text.isEmpty) {
      Log.error('Message is empty');
      return;
    }

    final bloc = DocumentBloc(
      documentId: documentId,
      saveToBlocMap: false,
    )..add(const DocumentEvent.initial());

    if (bloc.state.editorState == null) {
      await bloc.stream.firstWhere((state) => state.editorState != null);
    }

    final editorState = bloc.state.editorState;
    if (editorState == null) {
      Log.error("Can't get EditorState of document");
      return;
    }

    final messageDocument = customMarkdownToDocument(message.text);
    if (messageDocument.isEmpty) {
      Log.error('Failed to convert message to document');
      return;
    }

    final lastNodeOrNull = editorState.document.root.children.lastOrNull;

    final rootIsEmpty = lastNodeOrNull == null;
    final isLastLineEmpty = lastNodeOrNull?.children.isNotEmpty == false &&
        lastNodeOrNull?.delta?.isNotEmpty == false;

    final nodes = [
      if (rootIsEmpty || !isLastLineEmpty) paragraphNode(),
      ...messageDocument.root.children,
      paragraphNode(),
    ];
    final insertPath = rootIsEmpty ||
            listEquals(lastNodeOrNull.path, const [0]) && isLastLineEmpty
        ? const [0]
        : lastNodeOrNull.path.next;

    final transaction = editorState.transaction..insertNodes(insertPath, nodes);
    await editorState.apply(transaction);
    await bloc.close();
  }
}
