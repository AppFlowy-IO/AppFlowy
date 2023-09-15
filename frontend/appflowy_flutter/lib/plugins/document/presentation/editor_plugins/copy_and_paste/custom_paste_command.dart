import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/editor_state_paste_node_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_html.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_in_app_json.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_plain_text.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Paste.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CommandShortcutEvent customPasteCommand = CommandShortcutEvent(
  key: 'paste the content',
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

    // Order:
    // 1. in app json format
    // 2. html
    // 3. image
    // 4. plain text

    // try to paste the content in order, if any of them is failed, then try the next one
    if (inAppJson != null && inAppJson.isNotEmpty) {
      await editorState.deleteSelectionIfNeeded();
      final result = await editorState.pasteInAppJson(inAppJson);
      if (result) {
        return;
      }
    }

    if (html != null && html.isNotEmpty) {
      await editorState.deleteSelectionIfNeeded();
      final result = await editorState.pasteHtml(html);
      if (result) {
        return;
      }
    }

    if (image != null && image.$2?.isNotEmpty == true) {
      await editorState.deleteSelectionIfNeeded();
      final result = await editorState.pasteImage(image.$1, image.$2!);
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
