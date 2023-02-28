import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/core/document/document.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/text_delta.dart';
import 'package:appflowy_editor/src/core/legacy/built_in_attribute_keys.dart';
import 'package:flutter/material.dart';

class DeltaDocumentConvert {
  DeltaDocumentConvert();

  var _number = 1;
  final Map<int, List<TextNode>> _bulletedList = {};

  Document convertFromJSON(List<dynamic> json) {
    final delta = Delta.fromJson(json);
    return convertFromDelta(delta);
  }

  Document convertFromDelta(Delta delta) {
    final iter = delta.iterator;

    final document = Document.empty();
    TextNode textNode = TextNode(delta: Delta());
    int path = 0;

    while (iter.moveNext()) {
      final op = iter.current;
      if (op is TextInsert) {
        if (op.text != '\n') {
          // Attributes associated with a newline character describes formatting for that line.
          final texts = op.text.split('\n');
          if (texts.length > 1) {
            textNode.delta.insert(texts[0]);
            document.insert([path++], [textNode]);
            textNode = TextNode(delta: Delta()..insert(texts[1]));
          } else {
            _applyStyle(textNode, op.text, op.attributes);
          }
        } else {
          if (!_containNumberListStyle(op.attributes)) {
            _number = 1;
          }
          _applyListStyle(textNode, op.attributes);
          _applyHeaderStyle(textNode, op.attributes);
          _applyIndent(textNode, op.attributes);
          _applyBlockquote(textNode, op.attributes);
          // _applyCodeBlock(textNode, op.attributes);

          if (_containIndentBulletedListStyle(op.attributes)) {
            final level = _indentLevel(op.attributes);
            final path = [
              ..._bulletedList[level - 1]!.last.path,
              _bulletedList[level]!.length - 1,
            ];
            document.insert(path, [textNode]);
          } else {
            document.insert([path++], [textNode]);
          }
          textNode = TextNode(delta: Delta());
        }
      } else {
        assert(false, 'op must be TextInsert');
      }
    }

    return document;
  }

  void _applyStyle(TextNode textNode, String text, Map? attributes) {
    Attributes attrs = {};

    if (_containsStyle(attributes, 'strike')) {
      attrs[BuiltInAttributeKey.strikethrough] = true;
    }
    if (_containsStyle(attributes, 'underline')) {
      attrs[BuiltInAttributeKey.underline] = true;
    }
    if (_containsStyle(attributes, 'bold')) {
      attrs[BuiltInAttributeKey.bold] = true;
    }
    if (_containsStyle(attributes, 'italic')) {
      attrs[BuiltInAttributeKey.italic] = true;
    }
    final link = attributes?['link'] as String?;
    if (link != null) {
      attrs[BuiltInAttributeKey.href] = link;
    }
    final color = attributes?['color'] as String?;
    final colorHex = _convertColorToHexString(color);
    if (colorHex != null) {
      attrs[BuiltInAttributeKey.color] = colorHex;
    }
    final backgroundColor = attributes?['background'] as String?;
    final backgroundHex = _convertColorToHexString(backgroundColor);
    if (backgroundHex != null) {
      attrs[BuiltInAttributeKey.backgroundColor] = backgroundHex;
    }

    textNode.delta.insert(text, attributes: attrs);
  }

  bool _containsStyle(Map? attributes, String key) {
    final value = attributes?[key] as bool?;
    return value == true;
  }

  String? _convertColorToHexString(String? color) {
    if (color == null) {
      return null;
    }
    if (color.startsWith('#')) {
      return '0xFF${color.substring(1)}';
    } else if (color.startsWith("rgba")) {
      List rgbaList = color.substring(5, color.length - 1).split(',');
      return Color.fromRGBO(
        int.parse(rgbaList[0]),
        int.parse(rgbaList[1]),
        int.parse(rgbaList[2]),
        double.parse(rgbaList[3]),
      ).toHex();
    }
    return null;
  }

  // convert bullet-list, number-list, check-list to appflowy style list.
  void _applyListStyle(TextNode textNode, Map? attributes) {
    final indent = attributes?['indent'] as int?;
    final list = attributes?['list'] as String?;
    if (list != null) {
      switch (list) {
        case 'bullet':
          textNode.updateAttributes({
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.bulletedList,
          });
          if (indent != null) {
            _bulletedList[indent] ??= [];
            _bulletedList[indent]?.add(textNode);
          } else {
            _bulletedList.clear();
            _bulletedList[0] ??= [];
            _bulletedList[0]?.add(textNode);
          }
          break;
        case 'ordered':
          textNode.updateAttributes({
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.numberList,
            BuiltInAttributeKey.number: _number++,
          });
          break;
        case 'checked':
          textNode.updateAttributes({
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: true,
          });
          break;
        case 'unchecked':
          textNode.updateAttributes({
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: false,
          });
          break;
      }
    }
  }

  bool _containNumberListStyle(Map? attributes) {
    final list = attributes?['list'] as String?;
    return list == 'ordered';
  }

  bool _containIndentBulletedListStyle(Map? attributes) {
    final list = attributes?['list'] as String?;
    final indent = attributes?['indent'] as int?;
    return list == 'bullet' && indent != null;
  }

  int _indentLevel(Map? attributes) {
    final indent = attributes?['indent'] as int?;
    return indent ?? 1;
  }

  // convert header to appflowy style heading
  void _applyHeaderStyle(TextNode textNode, Map? attributes) {
    final header = attributes?['header'] as int?;
    if (header != null) {
      textNode.updateAttributes({
        BuiltInAttributeKey.subtype: BuiltInAttributeKey.heading,
        BuiltInAttributeKey.heading: 'h$header',
      });
    }
  }

  // convert indent to tab
  void _applyIndent(TextNode textNode, Map? attributes) {
    final indent = attributes?['indent'] as int?;
    final list = attributes?['list'] as String?;
    if (indent != null && list == null) {
      textNode.delta = textNode.delta.compose(
        Delta()
          ..retain(0)
          ..insert('  ' * indent),
      );
    }
  }

  /*
  // convert code-block to appflowy style code
  void _applyCodeBlock(TextNode textNode, Map? attributes) {
    final codeBlock = attributes?['code-block'] as bool?;
    if (codeBlock != null) {
      textNode.updateAttributes({
        BuiltInAttributeKey.subtype: 'code_block',
      });
    }
  }
  */

  void _applyBlockquote(TextNode textNode, Map? attributes) {
    final blockquote = attributes?['blockquote'] as bool?;
    if (blockquote != null) {
      textNode.updateAttributes({
        BuiltInAttributeKey.subtype: BuiltInAttributeKey.quote,
      });
    }
  }
}

extension on Color {
  String toHex() {
    return '0x${value.toRadixString(16)}';
  }
}
