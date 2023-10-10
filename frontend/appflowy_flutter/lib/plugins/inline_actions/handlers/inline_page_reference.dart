import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

class InlinePageReferenceService {
  InlinePageReferenceService({required this.currentViewId}) {
    init();
  }

  final Completer _initCompleter = Completer<void>();
  final String currentViewId;

  late final ViewBackendService service;
  List<InlineActionsMenuItem> _items = [];
  List<InlineActionsMenuItem> _filtered = [];

  Future<void> init() async {
    service = ViewBackendService();

    _generatePageItems(currentViewId).then((value) {
      _items = value;
      _filtered = value;
      _initCompleter.complete();
    });
  }

  Future<List<InlineActionsMenuItem>> _filterItems(String? search) async {
    await _initCompleter.future;

    if (search == null || search.isEmpty) {
      return _items;
    }

    return _items
        .where(
          (item) =>
              item.keywords != null &&
              item.keywords!.isNotEmpty &&
              item.keywords!.any(
                (keyword) => keyword.contains(search.toLowerCase()),
              ),
        )
        .toList();
  }

  Future<InlineActionsResult> inlinePageReferenceDelegate([
    String? search,
  ]) async {
    _filtered = await _filterItems(search);

    return InlineActionsResult(
      title: LocaleKeys.inlineActions_pageReference.tr(),
      results: _filtered,
    );
  }

  Future<List<InlineActionsMenuItem>> _generatePageItems(
    String currentViewId,
  ) async {
    final views = await service.fetchViews();
    if (views.isEmpty) {
      return [];
    }

    final List<InlineActionsMenuItem> pages = [];
    views.sort(((a, b) => b.createTime.compareTo(a.createTime)));

    for (final view in views) {
      if (view.id == currentViewId) {
        continue;
      }

      final pageSelectionMenuItem = InlineActionsMenuItem(
        keywords: [view.name.toLowerCase()],
        label: view.name,
        onSelected: (context, editorState, menuService, replace) async {
          final selection = editorState.selection;
          if (selection == null || !selection.isCollapsed) {
            return;
          }

          final node = editorState.getNodeAtPath(selection.end.path);
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
                }
              },
            );

          await editorState.apply(transaction);
        },
      );

      pages.add(pageSelectionMenuItem);
    }

    return pages;
  }
}
