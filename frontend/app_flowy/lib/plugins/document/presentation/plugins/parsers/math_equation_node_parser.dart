import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/node_parser.dart';

class MathEquationNodeParser extends NodeParser {
  const MathEquationNodeParser();

  @override
  String get id => 'math_equation';

  @override
  String transform(Node node) {
    return '\$\$${node.attributes[id]}\$\$';
  }
}
