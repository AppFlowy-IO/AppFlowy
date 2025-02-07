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
      /// filter date reminder node, and return it
      for (final o in delta) {
        final attribute = o.attributes ?? {};
        final Map? mention = attribute[MentionBlockKeys.mention] ?? {};
        final String date = mention?['date'] ?? '';
        if (date.isEmpty) continue;
        final dateTime = DateTime.tryParse(date);
        if (dateTime == null) continue;
        return '\n\n${DateFormat.yMMMd().format(dateTime)}\n\n';
      }
    }
    return const TextNodeParser().transform(node, encoder);
  }
}
