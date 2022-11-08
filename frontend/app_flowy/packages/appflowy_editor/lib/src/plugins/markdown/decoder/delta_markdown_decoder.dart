import 'dart:convert';

import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/core/document/text_delta.dart';
import 'package:appflowy_editor/src/core/legacy/built_in_attribute_keys.dart';
import 'package:markdown/markdown.dart' as md;

class DeltaMarkdownDecoder extends Converter<String, Delta>
    with md.NodeVisitor {
  final _delta = Delta();
  final Attributes _attributes = {};

  @override
  Delta convert(String input) {
    final document =
        md.Document(extensionSet: md.ExtensionSet.gitHubWeb).parseInline(input);
    for (final node in document) {
      node.accept(this);
    }
    return _delta;
  }

  @override
  void visitElementAfter(md.Element element) {
    _removeAttributeKey(element);
  }

  @override
  bool visitElementBefore(md.Element element) {
    _addAttributeKey(element);
    return true;
  }

  @override
  void visitText(md.Text text) {
    _delta.add(TextInsert(text.text, attributes: {..._attributes}));
  }

  void _addAttributeKey(md.Element element) {
    if (element.tag == 'strong') {
      _attributes[BuiltInAttributeKey.bold] = true;
    } else if (element.tag == 'em') {
      _attributes[BuiltInAttributeKey.italic] = true;
    } else if (element.tag == 'code') {
      _attributes[BuiltInAttributeKey.code] = true;
    } else if (element.tag == 'del') {
      _attributes[BuiltInAttributeKey.strikethrough] = true;
    } else if (element.tag == 'a') {
      _attributes[BuiltInAttributeKey.href] = element.attributes['href'];
    }
  }

  void _removeAttributeKey(md.Element element) {
    if (element.tag == 'strong') {
      _attributes.remove(BuiltInAttributeKey.bold);
    } else if (element.tag == 'em') {
      _attributes.remove(BuiltInAttributeKey.italic);
    } else if (element.tag == 'code') {
      _attributes.remove(BuiltInAttributeKey.code);
    } else if (element.tag == 'del') {
      _attributes.remove(BuiltInAttributeKey.strikethrough);
    } else if (element.tag == 'a') {
      _attributes.remove(BuiltInAttributeKey.href);
    }
  }
}
