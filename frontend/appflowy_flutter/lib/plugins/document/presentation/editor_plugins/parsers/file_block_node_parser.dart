import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class FileBlockNodeParser extends NodeParser {
  const FileBlockNodeParser();

  @override
  String get id => FileBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final name = node.attributes[FileBlockKeys.name];
    final url = node.attributes[FileBlockKeys.url];
    if (name == null || url == null) {
      return '';
    }
    return '[$name]($url)\n';
  }
}
