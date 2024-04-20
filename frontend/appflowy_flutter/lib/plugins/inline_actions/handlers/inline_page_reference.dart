import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/service_handler.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/command_palette/search_listener.dart';
import 'package:appflowy/workspace/application/command_palette/search_service.dart';
import 'package:appflowy/workspace/application/recent/cached_recent_service.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';

const _channel = "InlinePageReference";

class InlinePageReferenceService extends InlineActionsDelegate {
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

  late final CachedRecentService _recentService;
  List<InlineActionsMenuItem> _recentViews = [];

  final _searchListener = SearchListener(channel: _channel);
  Completer<List<SearchResultPB>>? _searchCompleter;

  bool _workspaceIdInitialized = false;
  final _workspaceIdCompleter = Completer<void>();
  String? _workspaceId;

  Future<void> init() async {
    _recentService = getIt<CachedRecentService>();
    _searchListener.start(
      onResultsChanged: _onResults,
      onResultsClosed: _onResults,
    );
    final views =
        (await _recentService.recentViews()).reversed.toSet().toList();

    // Filter by viewLayout
    views.retainWhere((i) => viewLayout == null || i.layout == viewLayout);

    // Map to InlineActionsMenuItem, then take 6 items (5 + current)
    // The 0th position (newest) is the current view.
    _recentViews = views.map(_fromView).take(6).toList()..removeAt(0);
    _initCompleter.complete();
  }

  void _onResults(RepeatedSearchResultPB results) {
    _searchCompleter?.complete(results.items);
  }

  Future<void> _initWorkspaceId() async {
    _workspaceIdInitialized = true;
    final results = await FolderEventGetCurrentWorkspaceSetting().send();
    final workspaceSettings = results.toNullable();

    if (workspaceSettings != null) {
      _workspaceId = workspaceSettings.workspaceId;
    }

    _workspaceIdCompleter.complete();
  }

  @override
  Future<void> dispose() async {
    await _searchListener.stop();
    _searchCompleter?.isCompleted == false
        ? _searchCompleter!.complete(const [])
        : null;
    await super.dispose();
  }

  @override
  Future<InlineActionsResult> search([
    String? search,
  ]) async {
    if (_workspaceId == null) {
      if (_workspaceIdInitialized && _workspaceIdCompleter.isCompleted) {
        return InlineActionsResult(
          title: LocaleKeys.inlineActions_pageReference.tr(),
          results: [],
        );
      }

      if (!_workspaceIdInitialized) {
        await _initWorkspaceId();
        await _workspaceIdCompleter.future;
      }
    }

    if (_workspaceId == null) {
      return InlineActionsResult(
        title: LocaleKeys.inlineActions_pageReference.tr(),
        results: [],
      );
    }

    final isSearching = search != null && search.isNotEmpty;

    late List<InlineActionsMenuItem> items;
    if (isSearching) {
      items = [];
      _searchCompleter = Completer();
      await SearchBackendService.performSearch(
        search,
        workspaceId: _workspaceId,
        channel: _channel,
      );

      final results = await _searchCompleter!.future;
      for (final item in results) {
        final menuItem = await _fromSearchResult(item);
        if (menuItem != null) {
          items.add(menuItem);
        }
      }
    } else {
      items = _recentViews;
    }

    if (viewLayout != null) {}

    // _filtered = await _filterItems(search);
    return InlineActionsResult(
      title: customTitle?.isNotEmpty == true
          ? customTitle!
          : isSearching
              ? LocaleKeys.inlineActions_pageReference.tr()
              : 'Recent pages',
      results: items,
    );
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

  InlineActionsMenuItem _fromView(ViewPB view) => InlineActionsMenuItem(
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
        onSelected: (context, editorState, menu, replace) => insertPage
            ? _onInsertPageRef(view, context, editorState, replace)
            : _onInsertLinkRef(view, context, editorState, menu, replace),
      );

  Future<InlineActionsMenuItem?> _fromSearchResult(
    SearchResultPB result,
  ) async {
    final viewRes = await ViewBackendService.getView(result.viewId);
    final view = viewRes.toNullable();
    if (view == null) {
      return null;
    }

    return _fromView(view);
  }
}
