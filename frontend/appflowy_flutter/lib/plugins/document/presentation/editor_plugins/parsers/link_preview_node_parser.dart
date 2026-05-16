import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

class LinkPreviewNodeParser extends NodeParser {
  const LinkPreviewNodeParser();

  @override
  String get id => LinkPreviewBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final href = node.attributes[LinkPreviewBlockKeys.url];
    if (href == null) {
      return '';
    }
    return '[$href]($href)\n';
  }
}
