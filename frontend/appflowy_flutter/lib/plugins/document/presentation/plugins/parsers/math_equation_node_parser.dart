import 'package:appflowy_editor/appflowy_editor.dart';

class MathEquationNodeParser extends NodeParser {
  const MathEquationNodeParser();

  @override
  String get id => 'math_equation';

  @override
  String transform(final Node node) {
    return '\$\$${node.attributes[id]}\$\$';
  }
}
