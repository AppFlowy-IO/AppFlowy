import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_command.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';

enum MentionType {
  page;

  static MentionType fromString(String value) {
    switch (value) {
      case 'page':
        return page;
      default:
        throw UnimplementedError();
    }
  }
}

class MentionBlockKeys {
  const MentionBlockKeys._();

  static const mention = 'mention';
  static const type = 'type'; // MentionType, String
  static const pageId = 'page_id';
}

class InlinePageReferenceService {
  InlinePageReferenceService() {
    init();
  }

  final Completer _initCompleter = Completer<void>();

  late final ViewBackendService service;
  List<InlineActionsMenuItem> _items = [];
  List<InlineActionsMenuItem> _filtered = [];

  Future<void> init() async {
    service = ViewBackendService();

    _generatePageItems().then((value) {
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

  Future<List<InlineActionsMenuItem>> _generatePageItems() async {
    final views = await service.fetchViews();
    if (views.isEmpty) {
      return [];
    }

    final List<InlineActionsMenuItem> pages = [];
    views.sort(((a, b) => b.createTime.compareTo(a.createTime)));

    for (final view in views) {
      final pageSelectionMenuItem = InlineActionsMenuItem(
        keywords: [view.name.toLowerCase()],
        label: FlowyText.regular(view.name),
        onSelected: (context, editorState, menuService) async {
          final selection = editorState.selection;
          if (selection == null || !selection.isCollapsed) {
            return;
          }

          final node = editorState.getNodeAtPath(selection.end.path);
          final delta = node?.delta;
          if (node == null || delta == null) {
            return;
          }

          final index = selection.endIndex;
          final lastKeywordIndex = delta
              .toPlainText()
              .substring(0, index)
              .lastIndexOf(inlineActionCharacter);

          // @page name -> $
          // preload the page infos
          pageMemorizer[view.id] = view;
          final transaction = editorState.transaction
            ..replaceText(
              node,
              lastKeywordIndex,
              index - lastKeywordIndex,
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
