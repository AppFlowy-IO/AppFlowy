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
    if (delta != null) {
      for (final o in delta) {
        final attribute = o.attributes ?? {};
        final Map? mention = attribute[MentionBlockKeys.mention] ?? {};
        if (mention == null) continue;

        /// filter date reminder node, and return it
        final String date = mention[MentionBlockKeys.date] ?? '';
        if (date.isNotEmpty) {
          final dateTime = DateTime.tryParse(date);
          if (dateTime == null) continue;
          return '${DateFormat.yMMMd().format(dateTime)}\n';
        }

        /// filter reference page
        final String pageId = mention[MentionBlockKeys.pageId] ?? '';
        if (pageId.isNotEmpty) {
          return '[]($pageId)\n';
        }
      }
    }
    return const TextNodeParser().transform(node, encoder);
  }
}
