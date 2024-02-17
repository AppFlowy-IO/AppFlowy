import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';

class InlinePageReferenceService {
  InlinePageReferenceService({
    required this.currentViewId,
    this.viewLayout,
    this.customTitle,
    this.insertPage = false,
    this.limitResults = 0,
  }) {
    init();
  }

  final Completer _initCompleter = Completer<void>();

  final String currentViewId;
  final ViewLayoutPB? viewLayout;
  final String? customTitle;

  /// Defaults to false, if set to true the Page
  /// will be inserted as a Reference
  /// When false, a link to the view will be inserted
  ///
  final bool insertPage;

  /// Defaults to 0 where there are no limits
  /// Anything above 0 will limit the page reference results
  /// to [limitResults].
  ///
  final int limitResults;

  final ViewBackendService service = ViewBackendService();
  List<InlineActionsMenuItem> _items = [];
  List<InlineActionsMenuItem> _filtered = [];

  Future<void> init() async {
    _items = await _generatePageItems(currentViewId, viewLayout);
    _filtered = limitResults > 0 ? _items.take(limitResults).toList() : _items;
    _initCompleter.complete();
  }

  Future<List<InlineActionsMenuItem>> _filterItems(String? search) async {
    await _initCompleter.future;

    final items = (search == null || search.isEmpty)
        ? _items
        : _items.where(
            (item) =>
                item.keywords != null &&
                item.keywords!.isNotEmpty &&
                item.keywords!.any(
                  (keyword) => keyword.contains(search.toLowerCase()),
                ),
          );

    return limitResults > 0
        ? items.take(limitResults).toList()
        : items.toList();
  }

  Future<InlineActionsResult> inlinePageReferenceDelegate([
    String? search,
  ]) async {
    _filtered = await _filterItems(search);

    return InlineActionsResult(
      title: customTitle?.isNotEmpty == true
          ? customTitle!
          : LocaleKeys.inlineActions_pageReference.tr(),
      results: _filtered,
    );
  }

  Future<List<InlineActionsMenuItem>> _generatePageItems(
    String currentViewId,
    ViewLayoutPB? viewLayout,
  ) async {
    late List<ViewPB> views;
    if (viewLayout != null) {
      views = await service.fetchViewsWithLayoutType(viewLayout);
    } else {
      views = await service.fetchViews();
    }

    if (views.isEmpty) {
      return [];
    }

    final List<InlineActionsMenuItem> pages = [];
    views.sort((a, b) => b.createTime.compareTo(a.createTime));

    for (final view in views) {
      if (view.id == currentViewId) {
        continue;
      }

      final pageSelectionMenuItem = InlineActionsMenuItem(
        keywords: [view.name.toLowerCase()],
        label: view.name,
        icon: (onSelected) => view.icon.value.isNotEmpty
            ? EmojiText(
                emoji: view.icon.value,
                fontSize: 12,
                textAlign: TextAlign.center,
                lineHeight: 1.3,
              )
            : view.defaultIcon(),
        onSelected: (context, editorState, menuService, replace) => insertPage
            ? _onInsertPageRef(view, context, editorState, replace)
            : _onInsertLinkRef(
                view,
                context,
                editorState,
                menuService,
                replace,
              ),
      );

      pages.add(pageSelectionMenuItem);
    }

    return pages;
  }

  Future<void> _onInsertPageRef(
    ViewPB view,
    BuildContext context,
    EditorState editorState,
    (int, int) replace,
  ) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final node = editorState.getNodeAtPath(selection.start.path);

    if (node != null) {
      // Delete search term
      if (replace.$2 > 0) {
        final transaction = editorState.transaction
          ..deleteText(node, replace.$1, replace.$2);
        await editorState.apply(transaction);
      }

      // Insert newline before inserting referenced database
      if (node.delta?.toPlainText().isNotEmpty == true) {
        await editorState.insertNewLine();
      }
    }

    try {
      await editorState.insertReferencePage(view, view.layout);
    } on FlowyError catch (e) {
      if (context.mounted) {
        return Dialogs.show(
          context,
          child: FlowyErrorPage.message(
            e.msg,
            howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
          ),
        );
      }
    }
  }

  Future<void> _onInsertLinkRef(
    ViewPB view,
    BuildContext context,
    EditorState editorState,
    InlineActionsMenuService menuService,
    (int, int) replace,
  ) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final node = editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    // @page name -> $
    // preload the page infos
    pageMemorizer[view.id] = view;
    final transaction = editorState.transaction
      ..replaceText(
        node,
        replace.$1,
        replace.$2,
        '\$',
        attributes: {
          MentionBlockKeys.mention: {
            MentionBlockKeys.type: MentionType.page.name,
            MentionBlockKeys.pageId: view.id,
          },
        },
      );

    await editorState.apply(transaction);
  }
}
