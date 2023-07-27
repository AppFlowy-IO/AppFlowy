import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_date_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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

  static const mention = 'mention';
  static const type = 'type'; // MentionType, String
  static const pageId = 'page_id';
  static const date = 'date';
}

class MentionBlock extends StatelessWidget {
  const MentionBlock({
    super.key,
    required this.mention,
    required this.node,
    required this.index,
  });

  final Map<String, dynamic> mention;
  final Node node;
  final int index;

  @override
  Widget build(BuildContext context) {
    final type = MentionType.fromString(mention[MentionBlockKeys.type]);

    switch (type) {
      case MentionType.page:
        final String pageId = mention[MentionBlockKeys.pageId];
        return MentionPageBlock(
          key: ValueKey(pageId),
          pageId: pageId,
        );

      case MentionType.date:
        final String date = mention[MentionBlockKeys.date];
        return MentionDateBlock(
          key: ValueKey(date),
          date: date,
          node: node,
          index: index,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
