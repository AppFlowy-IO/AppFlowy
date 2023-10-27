import 'package:appflowy_editor/appflowy_editor.dart';

class CustomImageNodeParser extends NodeParser {
  const CustomImageNodeParser();

  @override
  String get id => ImageBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    assert(node.children.isEmpty);
    final url = node.attributes[ImageBlockKeys.url];
    assert(url != null);
    return '![]($url)\n';
  }
}
