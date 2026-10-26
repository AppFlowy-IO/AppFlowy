import 'package:appflowy/workspace/application/export/document_link_resolver.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class CustomParagraphNodeParser extends NodeParser {
  const CustomParagraphNodeParser();

  @override
  String get id => ParagraphBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final delta = node.delta;
    if (delta != null) {
      final resolvedDelta = resolveDeltaForExport(delta);
      final resolvedNode = node.copyWith(
        attributes: {...node.attributes, 'delta': resolvedDelta.toJson()},
      );
      return const TextNodeParser().transform(resolvedNode, encoder);
    }
    return const TextNodeParser().transform(node, encoder);
  }
}
