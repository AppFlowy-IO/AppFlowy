import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_date_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum MentionType {
  page,
  date,
  reminder;

  static MentionType fromString(String value) {
    switch (value) {
      case 'page':
        return page;
      case 'date':
        return date;
      case 'reminder':
        return reminder;
      default:
        throw UnimplementedError();
    }
  }
}

class MentionBlockKeys {
  const MentionBlockKeys._();

  static const uid = 'uid'; // UniqueID
  static const mention = 'mention';
  static const type = 'type'; // MentionType, String
  static const pageId = 'page_id';

  // Related to Reminder and Date blocks
  static const date = 'date';
  static const includeTime = 'include_time';
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

    switch (type) {
      case MentionType.page:
        final String pageId = mention[MentionBlockKeys.pageId];
        return MentionPageBlock(
          key: ValueKey(pageId),
          pageId: pageId,
          textStyle: textStyle,
        );
      case MentionType.reminder:
      case MentionType.date:
        final String date = mention[MentionBlockKeys.date];
        final BuildContext editorContext =
            context.read<EditorState>().document.root.context!;
        return MentionDateBlock(
          key: ValueKey(date),
          editorContext: editorContext,
          date: date,
          node: node,
          index: index,
          isReminder: type == MentionType.reminder,
          reminderId: type == MentionType.reminder
              ? mention[MentionBlockKeys.uid]
              : null,
          includeTime: mention[MentionBlockKeys.includeTime] ?? false,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
