import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/node_parser.dart';

class DividerNodeParser extends NodeParser {
  const DividerNodeParser();

  @override
  String get id => 'divider';

  @override
  String transform(Node node) {
    return '---\n';
  }
}
