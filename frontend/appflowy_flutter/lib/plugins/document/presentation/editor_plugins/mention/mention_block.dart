import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_date_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mention_link_block.dart';

export 'package:appflowy/shared/mention_block_keys.dart';

Node dateMentionNode() {
  return paragraphNode(
    delta: Delta(
      operations: [
        TextInsert(
          MentionBlockKeys.mentionChar,
          attributes: MentionBlockKeys.buildMentionDateAttributes(
            date: DateTime.now().toIso8601String(),
            reminderId: null,
            reminderOption: null,
            includeTime: false,
          ),
        ),
      ],
    ),
  );
}

class MentionBlock extends StatelessWidget {
  const MentionBlock({
    super.key,
    required this.mention,
    required this.node,
    required this.index,
    required this.textStyle,
  });

  final Map<String, dynamic> mention;
  final Node node;
  final int index;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final type = MentionType.fromString(mention[MentionBlockKeys.type]);
    final editorState = context.read<EditorState>();

    switch (type) {
      case MentionType.page:
        final String? pageId = mention[MentionBlockKeys.pageId] as String?;
        if (pageId == null) {
          return const SizedBox.shrink();
        }
        final String? blockId = mention[MentionBlockKeys.blockId] as String?;

        return MentionPageBlock(
          key: ValueKey(pageId),
          editorState: editorState,
          pageId: pageId,
          blockId: blockId,
          node: node,
          textStyle: textStyle,
          index: index,
        );
      case MentionType.childPage:
        final String? pageId = mention[MentionBlockKeys.pageId] as String?;
        if (pageId == null) {
          return const SizedBox.shrink();
        }

        return MentionSubPageBlock(
          key: ValueKey(pageId),
          editorState: editorState,
          pageId: pageId,
          node: node,
          textStyle: textStyle,
          index: index,
        );

      case MentionType.date:
        final String date = mention[MentionBlockKeys.date];
        final reminderOption = ReminderOption.values.firstWhereOrNull(
          (o) => o.name == mention[MentionBlockKeys.reminderOption],
        );

        return MentionDateBlock(
          key: ValueKey(date),
          editorState: editorState,
          date: date,
          node: node,
          textStyle: textStyle,
          index: index,
          reminderId: mention[MentionBlockKeys.reminderId],
          reminderOption: reminderOption ?? ReminderOption.none,
          includeTime: mention[MentionBlockKeys.includeTime] ?? false,
        );
      case MentionType.externalLink:
        final String? url = mention[MentionBlockKeys.url] as String?;
        if (url == null) {
          return const SizedBox.shrink();
        }
        return MentionLinkBlock(
          url: url,
          editorState: editorState,
          node: node,
          index: index,
        );
    }
  }
}
