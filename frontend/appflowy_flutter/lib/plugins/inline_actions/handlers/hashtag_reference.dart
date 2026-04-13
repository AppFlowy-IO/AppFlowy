import 'package:appflowy_editor/appflowy_editor.dart';

import '../../document/presentation/editor_plugins/hashtag/hashtag_block_keys.dart';
import '../inline_actions_result.dart';
import '../service_handler.dart';

class HashtagReferenceService extends InlineActionsDelegate {
  HashtagReferenceService({
    this.initialTags = const [
      'todo',
      'idea',
      'bug',
      'feature',
      'important',
    ],
  });

  final List<String> initialTags;

  @override
  Future<InlineActionsResult> search([String? search]) async {
    final term = (search ?? '').toLowerCase();

    final tags = initialTags
        .where((tag) => term.isEmpty || tag.toLowerCase().contains(term))
        .map(
          (tag) => InlineActionsMenuItem(
            label: '#$tag',
            keywords: [tag],
            onSelected: (context, editorState, menu, replace) async {
              final selection = editorState.selection;
              if (selection == null || !selection.isCollapsed) {
                return;
              }

              final node = editorState.getNodeAtPath(selection.start.path);
              if (node == null) return;

              final start = replace.$1;
              final length = replace.$2;

              final transaction = editorState.transaction
                ..replaceText(
                  node,
                  start,
                  length,
                  HashtagBlockKeys.hashtagChar,
                  attributes: HashtagBlockKeys.buildHashtagAttributes(
                    name: tag,
                  ),
                )
                ..insertText(
                  node,
                  start + 1,
                  ' ',
                )
                ..afterSelection = Selection.collapsed(
                  Position(
                    path: node.path,
                    offset: start + 2,
                  ),
                );

              menu.dismiss();
              await editorState.apply(transaction);
            },
          ),
        )
        .toList();

    return InlineActionsResult(
      title: 'Hashtags',
      results: tags,
      startsWithKeywords: const ['#'],
    );
  }
}