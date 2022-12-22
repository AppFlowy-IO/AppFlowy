import 'dart:convert';

import 'package:appflowy_editor/src/core/document/document.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/divider_node_parser.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/image_node_parser.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/node_parser.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/text_node_parser.dart';

class DocumentMarkdownEncoder extends Converter<Document, String> {
  DocumentMarkdownEncoder({
    this.parsers = const [
      TextNodeParser(),
      ImageNodeParser(),
      DividerNodeParser(),
    ],
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
