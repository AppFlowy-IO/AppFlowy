import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownCodeBlockParser extends CustomMarkdownParser {
  const MarkdownCodeBlockParser();

  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    if (element is! md.Element) {
      return [];
    }

    if (element.tag != 'pre') {
      return [];
    }

    final ec = element.children;
    if (ec == null || ec.isEmpty) {
      return [];
    }

    final code = ec.first;
    if (code is! md.Element || code.tag != 'code') {
      return [];
    }

    String? language;
    if (code.attributes.containsKey('class')) {
      final classes = code.attributes['class']!.split(' ');
      final languageClass = classes.firstWhere(
        (c) => c.startsWith('language-'),
        orElse: () => '',
      );
      language = languageClass.substring('language-'.length);
    }

    return [
      codeBlockNode(
        language: language,
        delta: Delta()..insert(code.textContent.trimRight()),
      ),
    ];
  }
}
