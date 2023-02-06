import 'package:appflowy_editor/appflowy_editor.dart';

class MathEquationNodeParser extends NodeParser {
  const MathEquationNodeParser();

  @override
  String get id => 'math_equation';

  @override
  String transform(Node node) {
    return '\$\$${node.attributes[id]}\$\$';
  }
}
