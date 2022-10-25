import 'package:app_flowy/workspace/application/markdown/src/parser/node_parser.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class ImageNodeParser extends NodeParser {
  const ImageNodeParser();

  @override
  String get id => 'image';

  @override
  String transform(Node node) {
    return '![](${node.attributes['image_src']})';
  }
}
