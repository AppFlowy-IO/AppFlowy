import 'package:flutter/material.dart';

import 'package:appflowy/plugins/inline_actions/handlers/inline_page_reference.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

InlineActionsMenuService? actionsMenuService;
Future<void> showLinkToPageMenu(
  EditorState editorState,
  SelectionMenuService menuService,
  ViewLayoutPB pageType,
) async {
  menuService.dismiss();
  actionsMenuService?.dismiss();

  final rootContext = editorState.document.root.context;
  if (rootContext == null) {
    return;
  }

  // ignore: use_build_context_synchronously
  final service = InlineActionsService(
    context: rootContext,
    handlers: [
      InlinePageReferenceService(
        currentViewId: "",
        viewLayout: pageType,
      ).inlinePageReferenceDelegate,
    ],
  );

  final List<InlineActionsResult> initialResults = [];
  for (final handler in service.handlers) {
    final group = await handler();

    if (group.results.isNotEmpty) {
      initialResults.add(group);
    }
  }

  if (rootContext.mounted) {
    actionsMenuService = InlineActionsMenu(
      context: rootContext,
      editorState: editorState,
      service: service,
      initialResults: initialResults,
      style: Theme.of(editorState.document.root.context!).brightness ==
              Brightness.light
          ? const InlineActionsMenuStyle.light()
          : const InlineActionsMenuStyle.dark(),
      startCharAmount: 0,
    );

    actionsMenuService?.show();
  }
}
