import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class MathEquationNodeParser extends NodeParser {
  const MathEquationNodeParser();

  @override
  String get id => MathEquationBlockKeys.type;

  @override
  String transform(Node node) {
    return '\$\$${node.attributes[id]}\$\$';
  }
}
