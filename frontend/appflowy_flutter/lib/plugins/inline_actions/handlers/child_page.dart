import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/service_handler.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class InlineChildPageService extends InlineActionsDelegate {
  InlineChildPageService({required this.currentViewId});

  final String currentViewId;

  @override
  Future<InlineActionsResult> search(String? search) async {
    final List<InlineActionsMenuItem> results = [];
    if (search != null && search.isNotEmpty) {
      results.add(
        InlineActionsMenuItem(
          label: LocaleKeys.inlineActions_createPage.tr(args: [search]),
          icon: (_) => const FlowySvg(FlowySvgs.add_s),
          onSelected: (context, editorState, service, replacement) =>
              _onSelected(context, editorState, service, replacement, search),
        ),
      );
    }

    return InlineActionsResult(results: results);
  }

  Future<void> _onSelected(
    BuildContext context,
    EditorState editorState,
    InlineActionsMenuService service,
    (int, int) replacement,
    String? search,
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

    final view = (await ViewBackendService.createView(
      layoutType: ViewLayoutPB.Document,
      parentViewId: currentViewId,
      name: search!,
    ))
        .toNullable();

    if (view == null) {
      return Log.error('Failed to create view');
    }

    // preload the page info
    pageMemorizer[view.id] = view;
    final transaction = editorState.transaction
      ..replaceText(
        node,
        replacement.$1,
        replacement.$2,
        MentionBlockKeys.mentionChar,
        attributes: {
          MentionBlockKeys.mention: {
            MentionBlockKeys.type: MentionType.childPage.name,
            MentionBlockKeys.pageId: view.id,
          },
        },
      );

    await editorState.apply(transaction);
  }
}
