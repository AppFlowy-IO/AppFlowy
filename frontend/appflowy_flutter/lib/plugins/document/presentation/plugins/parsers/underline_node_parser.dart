import 'package:appflowy_editor/appflowy_editor.dart';

class UnderlineNodeParser extends NodeParser {
  const UnderlineNodeParser();

  @override
  String get id => 'underline';

  @override
  String transform(Node node) {
    return '<u>${node.attributes['underline']}</u>';
  }
}
