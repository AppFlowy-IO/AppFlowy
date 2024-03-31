import 'package:flutter/material.dart';

import 'package:appflowy/plugins/inline_actions/handlers/inline_page_reference.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

const _bracketChar = '[';
const _plusChar = '+';

CharacterShortcutEvent pageReferenceShortcutBrackets(
  BuildContext context,
  String viewId,
  InlineActionsMenuStyle style,
) =>
    CharacterShortcutEvent(
      key: 'show the inline page reference menu by [',
      character: _bracketChar,
      handler: (editorState) => inlinePageReferenceCommandHandler(
        _bracketChar,
        context,
        viewId,
        editorState,
        style,
        previousChar: _bracketChar,
      ),
    );

CharacterShortcutEvent pageReferenceShortcutPlusSign(
  BuildContext context,
  String viewId,
  InlineActionsMenuStyle style,
) =>
    CharacterShortcutEvent(
      key: 'show the inline page reference menu by +',
      character: _plusChar,
      handler: (editorState) => inlinePageReferenceCommandHandler(
        _plusChar,
        context,
        viewId,
        editorState,
        style,
      ),
    );

InlineActionsMenuService? selectionMenuService;
Future<bool> inlinePageReferenceCommandHandler(
  String character,
  BuildContext context,
  String currentViewId,
  EditorState editorState,
  InlineActionsMenuStyle style, {
  String? previousChar,
}) async {
  final selection = editorState.selection;
  if (PlatformExtension.isMobile || selection == null) {
    return false;
  }

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  // Check for previous character
  if (previousChar != null) {
    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null || delta.isEmpty) {
      return false;
    }

    if (selection.end.offset > 0) {
      final plain = delta.toPlainText();

      final previousCharacter = plain[selection.end.offset - 1];
      if (previousCharacter != _bracketChar) {
        return false;
      }
    }
  }

  if (!context.mounted) {
    return false;
  }

  final service = InlineActionsService(
    context: context,
    handlers: [
      InlinePageReferenceService(
        currentViewId: currentViewId,
        limitResults: 10,
      ),
    ],
  );

  await editorState.insertTextAtPosition(character, position: selection.start);

  final List<InlineActionsResult> initialResults = [];
  for (final handler in service.handlers) {
    final group = await handler.search(null);

    if (group.results.isNotEmpty) {
      initialResults.add(group);
    }
  }

  if (context.mounted) {
    selectionMenuService = InlineActionsMenu(
      context: service.context!,
      editorState: editorState,
      service: service,
      initialResults: initialResults,
      style: style,
      startCharAmount: previousChar != null ? 2 : 1,
    );

    selectionMenuService?.show();
  }

  return true;
}
