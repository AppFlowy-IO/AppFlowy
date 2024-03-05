import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/inline_actions/handlers/inline_page_reference.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

InlineActionsMenuService? _actionsMenuService;
Future<void> showLinkToPageMenu(
  EditorState editorState,
  SelectionMenuService menuService,
  ViewLayoutPB pageType,
) async {
  menuService.dismiss();
  _actionsMenuService?.dismiss();

  final rootContext = editorState.document.root.context;
  if (rootContext == null) {
    return;
  }

  final service = InlineActionsService(
    context: rootContext,
    handlers: [
      InlinePageReferenceService(
        currentViewId: "",
        viewLayout: pageType,
        customTitle: titleFromPageType(pageType),
        insertPage: pageType != ViewLayoutPB.Document,
        limitResults: 15,
      ),
    ],
  );

  final List<InlineActionsResult> initialResults = [];
  for (final handler in service.handlers) {
    final group = await handler.search(null);

    if (group.results.isNotEmpty) {
      initialResults.add(group);
    }
  }

  if (rootContext.mounted) {
    _actionsMenuService = InlineActionsMenu(
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

    _actionsMenuService?.show();
  }
}

String titleFromPageType(ViewLayoutPB layout) => switch (layout) {
      ViewLayoutPB.Grid => LocaleKeys.inlineActions_gridReference.tr(),
      ViewLayoutPB.Document => LocaleKeys.inlineActions_docReference.tr(),
      ViewLayoutPB.Board => LocaleKeys.inlineActions_boardReference.tr(),
      ViewLayoutPB.Calendar => LocaleKeys.inlineActions_calReference.tr(),
      _ => LocaleKeys.inlineActions_pageReference.tr(),
    };
