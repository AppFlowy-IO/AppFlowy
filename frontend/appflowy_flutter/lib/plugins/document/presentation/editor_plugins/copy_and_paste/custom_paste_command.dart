import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_block_link.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_html.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_in_app_json.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_plain_text.dart';
import 'package:appflowy/shared/clipboard_state.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/default_extensions.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:string_validator/string_validator.dart';
import 'package:universal_platform/universal_platform.dart';

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

final CommandShortcutEvent customPastePlainTextCommand = CommandShortcutEvent(
  key: 'paste the plain content',
  getDescription: () => AppFlowyEditorL10n.current.cmdPasteContent,
  command: 'ctrl+shift+v',
  macOSCommand: 'cmd+shift+v',
  handler: _pastePlainCommandHandler,
);

CommandShortcutEventHandler _pasteCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  doPaste(editorState).then((_) {
    final context = editorState.document.root.context;
    if (context != null && context.mounted) {
      context.read<ClipboardState>().didPaste();
    }
  });

  return KeyEventResult.handled;
};

CommandShortcutEventHandler _pastePlainCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  doPlainPaste(editorState).then((_) {
    final context = editorState.document.root.context;
    if (context != null && context.mounted) {
      context.read<ClipboardState>().didPaste();
    }
  });

  return KeyEventResult.handled;
};

Future<void> doPaste(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null) {
    return;
  }

  EditorNotification.paste().post();

  // dispatch the paste event
  final data = await getIt<ClipboardService>().getData();
  final inAppJson = data.inAppJson;
  final html = data.html;
  final plainText = data.plainText;
  final image = data.image;

  // dump the length of the data here, don't log the data itself for privacy concerns
  Log.info('paste command: inAppJson: ${inAppJson?.length}');
  Log.info('paste command: html: ${html?.length}');
  Log.info('paste command: plainText: ${plainText?.length}');
  Log.info('paste command: image: ${image?.$2?.length}');

  if (await editorState.pasteAppFlowySharePageLink(plainText)) {
    return Log.info('Pasted block link');
  }

  // paste as link preview
  if (await _pasteAsLinkPreview(editorState, plainText)) {
    return Log.info('Pasted as link preview');
  }

  // Order:
  // 1. in app json format
  // 2. html
  // 3. image
  // 4. plain text

  // try to paste the content in order, if any of them is failed, then try the next one
  if (inAppJson != null && inAppJson.isNotEmpty) {
    if (await editorState.pasteInAppJson(inAppJson)) {
      return Log.info('Pasted in app json');
    }
  }

  // if the image data is not null, we should handle it first
  // because the image URL in the HTML may not be reachable due to permission issues
  // For example, when pasting an image from Slack, the image URL provided is not public.
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
      selection: selection,
    );
    if (result) {
      return Log.info('Pasted image');
    }
  }

  if (html != null && html.isNotEmpty) {
    await editorState.deleteSelectionIfNeeded();
    if (await editorState.pasteHtml(html)) {
      return Log.info('Pasted html');
    }
  }

  if (plainText != null && plainText.isNotEmpty) {
    final currentSelection = editorState.selection;
    if (currentSelection == null) {
      await editorState.updateSelectionWithReason(
        selection,
        reason: SelectionUpdateReason.uiEvent,
      );
    }
    await editorState.pasteText(plainText);
    return Log.info('Pasted plain text');
  }

  return Log.info('unable to parse the clipboard content');
}

Future<bool> _pasteAsLinkPreview(
  EditorState editorState,
  String? text,
) async {
  final isMobile = UniversalPlatform.isMobile;
  // the url should contain a protocol
  if (text == null || !isURL(text, {'require_protocol': true})) {
    return false;
  }

  final selection = editorState.selection;
  // Apply the update only when the selection is collapsed
  // and at the start of the current line
  if (selection == null ||
      !selection.isCollapsed ||
      selection.startIndex != 0) {
    return false;
  }

  final node = editorState.getNodeAtPath(selection.start.path);
  // Apply the update only when the current node is a paragraph
  // and the paragraph is empty
  if (node == null ||
      node.type != ParagraphBlockKeys.type ||
      node.delta?.toPlainText().isNotEmpty == true) {
    return false;
  }

  final bool isImageUrl;
  try {
    isImageUrl = await _isImageUrl(text);
  } catch (e) {
    Log.info('unable to get content header');
    return false;
  }

  if (!isMobile && !isImageUrl) return false;

  // insert the text with link format
  final textTransaction = editorState.transaction
    ..insertText(
      node,
      0,
      text,
      attributes: {AppFlowyRichTextKeys.href: text},
    );
  await editorState.apply(
    textTransaction,
    skipHistoryDebounce: true,
  );

  // convert it to image or link preview node
  final replacementInsertedNodes = [
    isImageUrl ? imageNode(url: text) : linkPreviewNode(url: text),
    // if the next node is null, insert a empty paragraph node
    if (node.next == null) paragraphNode(),
  ];

  final replacementTransaction = editorState.transaction
    ..insertNodes(
      selection.start.path,
      replacementInsertedNodes,
    )
    ..deleteNode(node)
    ..afterSelection = Selection.collapsed(
      Position(path: node.path.next),
    );

  await editorState.apply(replacementTransaction);

  return true;
}

Future<void> doPlainPaste(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null) {
    return;
  }

  EditorNotification.paste().post();

  // dispatch the paste event
  final data = await getIt<ClipboardService>().getData();
  final plainText = data.plainText;
  if (plainText != null && plainText.isNotEmpty) {
    await editorState.pastePlainText(plainText);
    Log.info('Pasted plain text');
    return;
  }

  Log.info('unable to parse the clipboard content');
  return;
}

Future<bool> _isImageUrl(String text) async {
  final response = await http.head(Uri.parse(text));

  if (response.statusCode == 200) {
    final contentType = response.headers['content-type'];
    if (contentType != null) {
      return contentType.startsWith('image/') &&
          defaultImageExtensions.any(contentType.contains);
    }
  }

  throw 'bad status code';
}
