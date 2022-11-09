import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/node_parser.dart';

class ImageNodeParser extends NodeParser {
  const ImageNodeParser();

  @override
  String get id => 'image';

  @override
  String transform(Node node) {
    return '![](${node.attributes['image_src']})';
  }
}
