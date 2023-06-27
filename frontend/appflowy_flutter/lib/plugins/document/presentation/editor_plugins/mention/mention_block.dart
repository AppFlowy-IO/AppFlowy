import 'package:appflowy/plugins/document/presentation/editor_plugins/inline_page/inline_page_reference.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:flutter/material.dart';

class MentionBlock extends StatelessWidget {
  const MentionBlock({
    super.key,
    required this.mention,
  });

  final Map mention;

  @override
  Widget build(BuildContext context) {
    final type = MentionType.fromString(mention[MentionBlockKeys.type]);
    if (type == MentionType.page) {
      final pageId = mention[MentionBlockKeys.pageId];
      return MentionPageBlock(key: ValueKey(pageId), pageId: pageId);
    }
    throw UnimplementedError();
  }
}
