import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_date_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum MentionType {
  page,
  reminder,
  date,
  childPage;

  static MentionType fromString(String value) => switch (value) {
        'page' => page,
        'date' => date,
        'childPage' => childPage,
        // Backwards compatibility
        'reminder' => date,
        _ => throw UnimplementedError(),
      };
}

Node dateMentionNode() {
  return paragraphNode(
    delta: Delta(
      operations: [
        TextInsert(
          MentionBlockKeys.mentionChar,
          attributes: {
            MentionBlockKeys.mention: {
              MentionBlockKeys.type: MentionType.date.name,
              MentionBlockKeys.date: DateTime.now().toIso8601String(),
            },
          },
        ),
      ],
    ),
  );
}

class MentionBlockKeys {
  const MentionBlockKeys._();

  static const reminderId = 'reminder_id'; // ReminderID
  static const mention = 'mention';
  static const type = 'type'; // MentionType, String
  static const pageId = 'page_id';
  static const blockId = 'block_id';

  // Related to Reminder and Date blocks
  static const date = 'date'; // Start Date
  static const includeTime = 'include_time';
  static const reminderOption = 'reminder_option';

  static const mentionChar = '\$';
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
      case MentionType.page || MentionType.childPage:
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
          isSubPage: type == MentionType.childPage
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
          reminderOption: reminderOption,
          includeTime: mention[MentionBlockKeys.includeTime] ?? false,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
