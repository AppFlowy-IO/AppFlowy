import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class CodeBlockNodeParser extends NodeParser {
  const CodeBlockNodeParser();

  @override
  String get id => CodeBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final delta = node.delta;
    final language = node.attributes[CodeBlockKeys.language] ?? '';
    if (delta == null) {
      throw Exception('Delta is null');
    }
    final markdown = DeltaMarkdownEncoder().convert(delta);
    final result = '```$language\n$markdown\n```';
    final suffix = node.next == null ? '' : '\n';

    return '$result$suffix';
  }
}
