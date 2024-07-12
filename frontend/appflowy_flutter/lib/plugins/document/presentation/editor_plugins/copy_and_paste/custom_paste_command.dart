import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/editor_state_paste_node_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_html.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_in_app_json.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_plain_text.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';

/// - support
///   - desktop
///   - web
///   - mobile
///
final CommandShortcutEvent customPasteCommand = CommandShortcutEvent(
  key: 'paste the content',
  getDescription: () => AppFlowyEditorL10n.current.cmdPasteContent,
  command: 'ctrl+v',
  macOSCommand: 'cmd+v',
  handler: _pasteCommandHandler,
);

CommandShortcutEventHandler _pasteCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  // because the event handler is not async, so we need to use wrap the async function here
  () async {
    // dispatch the paste event
    final data = await getIt<ClipboardService>().getData();
    final inAppJson = data.inAppJson;
    final html = data.html;
    final plainText = data.plainText;
    final image = data.image;

    // paste as link preview
    if (await _pasteAsLinkPreview(editorState, plainText)) {
      return;
    }

    // Order:
    // 1. in app json format
    // 2. html
    // 3. image
    // 4. plain text

    // try to paste the content in order, if any of them is failed, then try the next one
    if (inAppJson != null && inAppJson.isNotEmpty) {
      debugPrint('paste in app json: $inAppJson');
      await editorState.deleteSelectionIfNeeded();
      if (await editorState.pasteInAppJson(inAppJson)) {
        return;
      }
    }

    if (html != null && html.isNotEmpty) {
      await editorState.deleteSelectionIfNeeded();
      if (await editorState.pasteHtml(html)) {
        return;
      }
    }

    if (image != null && image.$2?.isNotEmpty == true) {
      final documentBloc =
          editorState.document.root.context?.read<DocumentBloc>();
      final documentId = documentBloc?.documentId;
      if (documentId == null || documentId.isEmpty) {
        return;
      }
      await editorState.deleteSelectionIfNeeded();
      final result = await editorState.pasteImage(
        image.$1,
        image.$2!,
        documentId,
      );
      if (result) {
        return;
      }
    }

    if (plainText != null && plainText.isNotEmpty) {
      await editorState.pastePlainText(plainText);
    }
  }();

  return KeyEventResult.handled;
};

Future<bool> _pasteAsLinkPreview(
  EditorState editorState,
  String? text,
) async {
  if (text == null || !isURL(text)) {
    return false;
  }

  final selection = editorState.selection;
  if (selection == null ||
      !selection.isCollapsed ||
      selection.startIndex != 0) {
    return false;
  }

  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null ||
      node.type != ParagraphBlockKeys.type ||
      node.delta?.toPlainText().isNotEmpty == true) {
    return false;
  }

  final transaction = editorState.transaction;
  transaction.insertNode(
    selection.start.path,
    linkPreviewNode(url: text),
  );
  await editorState.apply(transaction);

  return true;
}
