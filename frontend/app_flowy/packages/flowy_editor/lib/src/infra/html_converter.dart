import 'dart:collection';

import 'package:flowy_editor/src/document/attributes.dart';
import 'package:flowy_editor/src/document/node.dart';
import 'package:flowy_editor/src/document/text_delta.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html;

const String tagH1 = "h1";
const String tagH2 = "h2";
const String tagH3 = "h3";
const String tagOrderedList = "ol";
const String tagUnorderedList = "ul";
const String tagList = "li";
const String tagParagraph = "p";
const String tagImage = "img";
const String tagAnchor = "a";
const String tagItalic = "i";
const String tagBold = "b";
const String tagUnderline = "u";
const String tagDel = "del";
const String tagStrong = "strong";
const String tagSpan = "span";
const String tagCode = "code";

extension on Color {
  String toRgbaString() {
    return 'rgba($red, $green, $blue, $alpha)';
  }
}

/// Converting the HTML to nodes
class HTMLToNodesConverter {
  final html.Document _document;

  /// This flag is used for parsing HTML pasting from Google Docs
  /// Google docs wraps the the content inside the `<b></b>` tag. It's strange.
  ///
  /// If a `<b>` element is parsing in the <p>, we regard it as as text spans.
  /// Otherwise, it's parsed as a container.
  bool _inParagraph = false;

  HTMLToNodesConverter(String htmlString) : _document = parse(htmlString);

  List<Node> toNodes() {
    final childNodes = _document.body?.nodes.toList() ?? <html.Node>[];
    return _handleContainer(childNodes);
  }

  List<Node> _handleContainer(List<html.Node> childNodes) {
    final delta = Delta();
    final result = <Node>[];
    for (final child in childNodes) {
      if (child is html.Element) {
        if (child.localName == tagAnchor ||
            child.localName == tagSpan ||
            child.localName == tagCode ||
            child.localName == tagStrong ||
            child.localName == tagUnderline ||
            child.localName == tagItalic ||
            child.localName == tagDel) {
          _handleRichTextElement(delta, child);
        } else if (child.localName == tagBold) {
          // Google docs wraps the the content inside the `<b></b>` tag.
          // It's strange
          if (!_inParagraph) {
            result.addAll(_handleBTag(child));
          } else {
            result.add(_handleRichText(child));
          }
        } else {
          result.addAll(_handleElement(child));
        }
      } else {
        delta.insert(child.text ?? "");
      }
    }
    if (delta.isNotEmpty) {
      result.add(TextNode(type: "text", delta: delta));
    }
    return result;
  }

  List<Node> _handleBTag(html.Element element) {
    final childNodes = element.nodes;
    return _handleContainer(childNodes);
  }

  List<Node> _handleElement(html.Element element,
      [Map<String, dynamic>? attributes]) {
    if (element.localName == tagH1) {
      return [_handleHeadingElement(element, tagH1)];
    } else if (element.localName == tagH2) {
      return [_handleHeadingElement(element, tagH2)];
    } else if (element.localName == tagH3) {
      return [_handleHeadingElement(element, tagH3)];
    } else if (element.localName == tagUnorderedList) {
      return _handleUnorderedList(element);
    } else if (element.localName == tagOrderedList) {
      return _handleOrderedList(element);
    } else if (element.localName == tagList) {
      return _handleListElement(element);
    } else if (element.localName == tagParagraph) {
      return [_handleParagraph(element, attributes)];
    } else {
      final delta = Delta();
      delta.insert(element.text);
      if (delta.isNotEmpty) {
        return [TextNode(type: "text", delta: delta)];
      }
    }
    return [];
  }

  Node _handleParagraph(html.Element element,
      [Map<String, dynamic>? attributes]) {
    _inParagraph = true;
    final node = _handleRichText(element, attributes);
    _inParagraph = false;
    return node;
  }

  Map<String, String> _cssStringToMap(String? cssString) {
    final result = <String, String>{};
    if (cssString == null) {
      return result;
    }

    final entries = cssString.split(";");
    for (final entry in entries) {
      final tuples = entry.split(":");
      if (tuples.length < 2) {
        continue;
      }
      result[tuples[0].trim()] = tuples[1].trim();
    }

    return result;
  }

  Attributes? _getDeltaAttributesFromHtmlAttributes(
      LinkedHashMap<Object, String> htmlAttributes) {
    final attrs = <String, dynamic>{};
    final styleString = htmlAttributes["style"];
    final cssMap = _cssStringToMap(styleString);

    final fontWeightStr = cssMap["font-weight"];
    if (fontWeightStr != null) {
      if (fontWeightStr == "bold") {
        attrs[StyleKey.bold] = true;
      } else {
        int? weight = int.tryParse(fontWeightStr);
        if (weight != null && weight > 500) {
          attrs[StyleKey.bold] = true;
        }
      }
    }

    final textDecorationStr = cssMap["text-decoration"];
    if (textDecorationStr == "line-through") {
      attrs[StyleKey.strikethrough] = true;
    } else if (textDecorationStr == "underline") {
      attrs[StyleKey.underline] = true;
    }

    final backgroundColorStr = cssMap["background-color"];
    final backgroundColor = _tryParseCssColorString(backgroundColorStr);
    if (backgroundColor != null) {
      attrs[StyleKey.backgroundColor] =
          '0x${backgroundColor.value.toRadixString(16)}';
    }

    if (cssMap["font-style"] == "italic") {
      attrs[StyleKey.italic] = true;
    }

    return attrs.isEmpty ? null : attrs;
  }

  /// Try to parse the `rgba(red, greed, blue, alpha)`
  /// from the string.
  Color? _tryParseCssColorString(String? colorString) {
    if (colorString == null) {
      return null;
    }
    final reg = RegExp(r'rgba\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)');
    final match = reg.firstMatch(colorString);
    if (match == null) {
      return null;
    }

    if (match.groupCount < 4) {
      return null;
    }
    final redStr = match.group(1);
    final greenStr = match.group(2);
    final blueStr = match.group(3);
    final alphaStr = match.group(4);

    final red = redStr != null ? int.tryParse(redStr) : null;
    final green = greenStr != null ? int.tryParse(greenStr) : null;
    final blue = blueStr != null ? int.tryParse(blueStr) : null;
    final alpha = alphaStr != null ? int.tryParse(alphaStr) : null;

    if (red == null || green == null || blue == null || alpha == null) {
      return null;
    }

    return Color.fromARGB(alpha, red, green, blue);
  }

  _handleRichTextElement(Delta delta, html.Element element) {
    if (element.localName == tagSpan) {
      delta.insert(element.text,
          _getDeltaAttributesFromHtmlAttributes(element.attributes));
    } else if (element.localName == tagAnchor) {
      final hyperLink = element.attributes["href"];
      Map<String, dynamic>? attributes;
      if (hyperLink != null) {
        attributes = {"href": hyperLink};
      }
      delta.insert(element.text, attributes);
    } else if (element.localName == tagStrong || element.localName == tagBold) {
      delta.insert(element.text, {StyleKey.bold: true});
    } else if (element.localName == tagUnderline) {
      delta.insert(element.text, {StyleKey.underline: true});
    } else if (element.localName == tagItalic) {
      delta.insert(element.text, {StyleKey.italic: true});
    } else if (element.localName == tagDel) {
      delta.insert(element.text, {StyleKey.strikethrough: true});
    } else {
      delta.insert(element.text);
    }
  }

  /// A container contains a <input type="checkbox" > will
  /// be regarded as a checkbox block.
  ///
  /// A container contains a <img /> will be regarded as a image block
  Node _handleRichText(html.Element element,
      [Map<String, dynamic>? attributes]) {
    final image = element.querySelector(tagImage);
    if (image != null) {
      final imageNode = _handleImage(image);
      return imageNode;
    }
    final testInput = element.querySelector("input");
    bool checked = false;
    final isCheckbox =
        testInput != null && testInput.attributes["type"] == "checkbox";
    if (isCheckbox) {
      checked = testInput.attributes.containsKey("checked") &&
          testInput.attributes["checked"] != "false";
    }

    final delta = Delta();

    for (final child in element.nodes.toList()) {
      if (child is html.Element) {
        _handleRichTextElement(delta, child);
      } else {
        delta.insert(child.text ?? "");
      }
    }

    final textNode =
        TextNode(type: "text", delta: delta, attributes: attributes);
    if (isCheckbox) {
      textNode.attributes["subtype"] = StyleKey.checkbox;
      textNode.attributes["checkbox"] = checked;
    }
    return textNode;
  }

  Node _handleImage(html.Element element) {
    final src = element.attributes["src"];
    final attributes = <String, dynamic>{};
    if (src != null) {
      attributes["image_src"] = src;
    }
    return Node(type: "image", attributes: attributes, children: LinkedList());
  }

  List<Node> _handleUnorderedList(html.Element element) {
    final result = <Node>[];
    element.children.forEach((child) {
      result.addAll(
          _handleListElement(child, {"subtype": StyleKey.bulletedList}));
    });
    return result;
  }

  List<Node> _handleOrderedList(html.Element element) {
    final result = <Node>[];
    for (var i = 0; i < element.children.length; i++) {
      final child = element.children[i];
      result.addAll(_handleListElement(
          child, {"subtype": StyleKey.numberList, "number": i + 1}));
    }
    return result;
  }

  Node _handleHeadingElement(
    html.Element element,
    String headingStyle,
  ) {
    final delta = Delta();
    delta.insert(element.text);
    return TextNode(
        type: "text",
        attributes: {"subtype": "heading", "heading": headingStyle},
        delta: delta);
  }

  List<Node> _handleListElement(html.Element element,
      [Map<String, dynamic>? attributes]) {
    final result = <Node>[];
    final childNodes = element.nodes.toList();
    for (final child in childNodes) {
      if (child is html.Element) {
        result.addAll(_handleElement(child, attributes));
      }
    }
    return result;
  }
}

/// [NodesToHTMLConverter] is used to convert the nodes to HTML.
/// Can be used to copy & paste, exporting the document.
class NodesToHTMLConverter {
  final List<Node> nodes;
  final int? startOffset;
  final int? endOffset;
  final List<html.Node> _result = [];

  /// According to the W3C specs. The bullet list should be wrapped as
  ///
  /// <ul>
  ///   <li>xxx</li>
  ///   <li>xxx</li>
  ///   <li>xxx</li>
  /// </ul>
  ///
  /// This container is used to save the list elements temporarily.
  html.Element? _stashListContainer;

  NodesToHTMLConverter(
      {required this.nodes, this.startOffset, this.endOffset}) {
    if (nodes.isEmpty) {
      return;
    } else if (nodes.length == 1) {
      final first = nodes.first;
      if (first is TextNode) {
        nodes[0] = first.copyWith(
            delta: first.delta.slice(startOffset ?? 0, endOffset));
      }
    } else {
      final first = nodes.first;
      final last = nodes.last;
      if (first is TextNode) {
        nodes[0] = first.copyWith(delta: first.delta.slice(startOffset ?? 0));
      }
      if (last is TextNode) {
        nodes[nodes.length - 1] =
            last.copyWith(delta: last.delta.slice(0, endOffset));
      }
    }
  }

  List<html.Node> toHTMLNodes() {
    for (final node in nodes) {
      if (node.type == "text") {
        final textNode = node as TextNode;
        if (node == nodes.first) {
          _addTextNode(textNode);
        } else if (node == nodes.last) {
          _addTextNode(textNode, end: endOffset);
        } else {
          _addTextNode(textNode);
        }
      }
      // TODO: handle image and other blocks
    }
    if (_stashListContainer != null) {
      _result.add(_stashListContainer!);
      _stashListContainer = null;
    }
    return _result;
  }

  _addTextNode(TextNode textNode, {int? end}) {
    _addElement(textNode, _textNodeToHtml(textNode, end: end));
  }

  _addElement(TextNode textNode, html.Element element) {
    if (element.localName == tagList) {
      final isNumbered = textNode.attributes["subtype"] == StyleKey.numberList;
      _stashListContainer ??=
          html.Element.tag(isNumbered ? tagOrderedList : tagUnorderedList);
      _stashListContainer?.append(element);
    } else {
      if (_stashListContainer != null) {
        _result.add(_stashListContainer!);
        _stashListContainer = null;
      }
      _result.add(element);
    }
  }

  String toHTMLString() {
    final elements = toHTMLNodes();
    final copyString = elements.fold<String>(
        "", ((previousValue, element) => previousValue + stringify(element)));
    return copyString;
  }

  html.Element _textNodeToHtml(TextNode textNode, {int? end}) {
    String? subType = textNode.attributes["subtype"];
    return _deltaToHtml(textNode.delta,
        subType: subType,
        end: end,
        checked: textNode.attributes["checkbox"] == true);
  }

  String _attributesToCssStyle(Map<String, dynamic> attributes) {
    final cssMap = <String, String>{};
    if (attributes[StyleKey.backgroundColor] != null) {
      final color = Color(
        int.parse(attributes[StyleKey.backgroundColor]),
      );
      cssMap["background-color"] = color.toRgbaString();
    }
    if (attributes[StyleKey.color] != null) {
      final color = Color(
        int.parse(attributes[StyleKey.color]),
      );
      cssMap["color"] = color.toRgbaString();
    }
    if (attributes[StyleKey.bold] == true) {
      cssMap["font-weight"] = "bold";
    }
    if (attributes[StyleKey.strikethrough] == true) {
      cssMap["text-decoration"] = "line-through";
    }
    if (attributes[StyleKey.underline] == true) {
      cssMap["text-decoration"] = "underline";
    }
    if (attributes[StyleKey.italic] == true) {
      cssMap["font-style"] = "italic";
    }
    return _cssMapToCssStyle(cssMap);
  }

  String _cssMapToCssStyle(Map<String, String> cssMap) {
    return cssMap.entries.fold("", (previousValue, element) {
      final kv = '${element.key}: ${element.value}';
      if (previousValue.isEmpty) {
        return kv;
      }
      return '$previousValue; $kv';
    });
  }

  html.Element _deltaToHtml(Delta delta,
      {String? subType, int? end, bool? checked}) {
    if (end != null) {
      delta = delta.slice(0, end);
    }

    final childNodes = <html.Node>[];
    String tagName = tagParagraph;

    if (subType == StyleKey.bulletedList || subType == StyleKey.numberList) {
      tagName = tagList;
    } else if (subType == StyleKey.checkbox) {
      final node = html.Element.html('<input type="checkbox" />');
      if (checked != null && checked) {
        node.attributes["checked"] = "true";
      }
      childNodes.add(node);
    }

    for (final op in delta) {
      if (op is TextInsert) {
        final attributes = op.attributes;
        if (attributes != null) {
          if (attributes.length == 1 && attributes[StyleKey.bold] == true) {
            final strong = html.Element.tag(tagStrong);
            strong.append(html.Text(op.content));
            childNodes.add(strong);
          } else if (attributes.length == 1 &&
              attributes[StyleKey.underline] == true) {
            final strong = html.Element.tag(tagUnderline);
            strong.append(html.Text(op.content));
            childNodes.add(strong);
          } else if (attributes.length == 1 &&
              attributes[StyleKey.italic] == true) {
            final strong = html.Element.tag(tagItalic);
            strong.append(html.Text(op.content));
            childNodes.add(strong);
          } else if (attributes.length == 1 &&
              attributes[StyleKey.strikethrough] == true) {
            final strong = html.Element.tag(tagDel);
            strong.append(html.Text(op.content));
            childNodes.add(strong);
          } else {
            final span = html.Element.tag(tagSpan);
            final cssString = _attributesToCssStyle(attributes);
            if (cssString.isNotEmpty) {
              span.attributes["style"] = cssString;
            }
            span.append(html.Text(op.content));
            childNodes.add(span);
          }
        } else {
          childNodes.add(html.Text(op.content));
        }
      }
    }

    if (tagName != tagParagraph) {
      final p = html.Element.tag(tagParagraph);
      for (final node in childNodes) {
        p.append(node);
      }
      final result = html.Element.tag(tagList);
      result.append(p);
      return result;
    } else {
      final p = html.Element.tag(tagName);
      for (final node in childNodes) {
        p.append(node);
      }
      return p;
    }
  }
}

String stringify(html.Node node) {
  if (node is html.Element) {
    return node.outerHtml;
  }

  if (node is html.Text) {
    return node.text;
  }

  return "";
}
