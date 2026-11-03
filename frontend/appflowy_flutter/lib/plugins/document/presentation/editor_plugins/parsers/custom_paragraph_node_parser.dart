import 'package:appflowy/plugins/document/presentation/editor_plugins/hashtag/hashtag_block_keys.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

class CustomParagraphNodeParser extends NodeParser {
  const CustomParagraphNodeParser();

  @override
  String get id => ParagraphBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final delta = node.delta;
    if (delta == null) {
      return const TextNodeParser().transform(node, encoder);
    }

    String text = '';

    for (final o in delta) {
      final attributes = o.attributes ?? {};

      // Mentions
      final Map? mention = attributes[MentionBlockKeys.mention];
      if (mention != null) {
        /// filter date reminder node, and return it
        final String date = mention[MentionBlockKeys.date] ?? '';
        if (date.isNotEmpty) {
          final dateTime = DateTime.tryParse(date);
          if (dateTime != null) {
            text += DateFormat.yMMMd().format(dateTime);
            continue;
          }
        }

        /// filter reference page
        final String pageId = mention[MentionBlockKeys.pageId] ?? '';
        if (pageId.isNotEmpty) {
          text += '[]($pageId)';
          continue;
        }
      }

      // Hashtags
      final Map? hashtag = attributes[HashtagBlockKeys.hashtag];
      if (hashtag != null) {
        final String name = hashtag[HashtagBlockKeys.name] ?? '';
        if (name.isNotEmpty) {
          text += '#$name';
          continue;
        }
      }

      // Plain text
      if (o is TextInsert) {
        text += o.text;
      }
    }

    return '$text\n';
  }
}