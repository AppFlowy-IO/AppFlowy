import 'dart:convert';

import 'package:app_flowy/workspace/application/markdown/src/parser/image_node_parser.dart';
import 'package:app_flowy/workspace/application/markdown/src/parser/node_parser.dart';
import 'package:app_flowy/workspace/application/markdown/src/parser/text_node_parser.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class AppFlowyEditorMarkdownEncoder extends Converter<Document, String> {
  AppFlowyEditorMarkdownEncoder({
    this.parsers = const [
      TextNodeParser(),
      ImageNodeParser(),
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
