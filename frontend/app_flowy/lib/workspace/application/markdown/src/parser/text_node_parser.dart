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
    var result = markdown;
    var suffix = '';
    if (attributes.isNotEmpty &&
        attributes.containsKey(BuiltInAttributeKey.subtype)) {
      final subtype = attributes[BuiltInAttributeKey.subtype];
      if (node.next?.subtype != subtype) {
        suffix = '\n';
      }
      if (subtype == 'heading') {
        final heading = attributes[BuiltInAttributeKey.heading];
        if (heading == 'h1') {
          result = '# $markdown';
        } else if (heading == 'h2') {
          result = '## $markdown';
        } else if (heading == 'h3') {
          result = '### $markdown';
        } else if (heading == 'h4') {
          result = '#### $markdown';
        } else if (heading == 'h5') {
          result = '##### $markdown';
        } else if (heading == 'h6') {
          result = '###### $markdown';
        }
      } else if (subtype == 'quote') {
        result = '> $markdown';
      } else if (subtype == 'code') {
        result = '`$markdown`';
      } else if (subtype == 'code-block') {
        result = '```\n$markdown\n```';
      } else if (subtype == 'bulleted-list') {
        result = '- $markdown';
      } else if (subtype == 'number-list') {
        final number = attributes['number'];
        result = '$number. $markdown';
      } else if (subtype == 'checkbox') {
        if (attributes[BuiltInAttributeKey.checkbox] == true) {
          result = '- [x] $markdown';
        } else {
          result = '- [ ] $markdown';
        }
      }
    }
    return '$result$suffix';
  }
}
