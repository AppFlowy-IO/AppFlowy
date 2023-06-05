import 'package:appflowy_editor/appflowy_editor.dart';

class DividerNodeParser extends NodeParser {
  const DividerNodeParser();

  @override
  String get id => 'divider';

  @override
  String transform(final Node node) {
    return '---\n';
  }
}
