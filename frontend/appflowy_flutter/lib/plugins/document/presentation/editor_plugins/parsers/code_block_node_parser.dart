import 'package:appflowy_editor/appflowy_editor.dart';

class CodeBlockNodeParser extends NodeParser {
  const CodeBlockNodeParser();

  @override
  String get id => 'code_block';

  @override
  String transform(Node node) {
    return '```\n${node.attributes['code_block']}\n```';
  }
}
