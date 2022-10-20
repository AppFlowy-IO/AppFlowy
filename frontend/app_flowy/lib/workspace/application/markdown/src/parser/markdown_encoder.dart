import 'dart:convert';

import 'package:app_flowy/workspace/application/markdown/delta_markdown.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

abstract class NodeParser {
  const NodeParser();

  String get id;
  String transform(Node node);
}

class TextNodeParser extends NodeParser {
  const TextNodeParser();

  @override
  String get id => 'text';

  @override
  String transform(Node node) {
    assert(node is TextNode);
    final textNode = node as TextNode;
    final delta = jsonEncode(
      textNode.delta
        ..add(TextInsert('\n'))
        ..toJson(),
    );
    final markdown = deltaToMarkdown(delta);
    return markdown;
  }
}

class AppFlowyEditorMarkdownEncoder extends Converter<Document, String> {
  AppFlowyEditorMarkdownEncoder({
    this.parsers = const [TextNodeParser()],
  });

  final List<NodeParser> parsers;

  @override
  String convert(Document input) {
    final buffer = StringBuffer();
    for (final node in input.root.children) {
      NodeParser? parser =
          parsers.firstWhereOrNull((element) => element.id == node.type);
      if (parser != null) {
        buffer.write(parser.transform(node));
      }
    }
    return buffer.toString();
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
