import 'dart:convert';

import 'package:app_flowy/workspace/application/markdown/delta_markdown.dart';
import 'package:app_flowy/workspace/application/markdown/src/parser/node_parser.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

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
    final attributes = textNode.attributes;
    if (attributes.isNotEmpty &&
        attributes.containsKey(BuiltInAttributeKey.subtype)) {
      final subtype = attributes[BuiltInAttributeKey.subtype];
      if (subtype == 'h1') {
        return '# $markdown';
      } else if (subtype == 'h2') {
        return '## $markdown';
      } else if (subtype == 'h3') {
        return '### $markdown';
      } else if (subtype == 'quote') {
        return '> $markdown';
      } else if (subtype == 'code') {
        return '`$markdown`';
      } else if (subtype == 'code-block') {
        return '```\n$markdown\n```';
      } else if (subtype == 'bulleted-list') {
        return '- $markdown';
      } else if (subtype == 'number-list') {
        final number = attributes['number'];
        return '$number. $markdown';
      } else if (subtype == 'checkbox') {
        if (attributes[BuiltInAttributeKey.checkbox] == true) {
          return '- [x] $markdown';
        } else {
          return '- [ ] $markdown';
        }
      }
    }
    return markdown;
  }
}
