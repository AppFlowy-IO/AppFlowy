import 'dart:collection';

import 'package:flowy_editor/document/attributes.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
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
const String tagBold = "b";
const String tagStrong = "strong";
const String tagSpan = "span";
const String tagCode = "code";

/// Converting the HTML to nodes
class HTMLToNodesConverter {
  final html.Document _document;
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
            child.localName == tagStrong) {
          _handleRichTextElement(delta, child);
        } else if (child.localName == tagBold) {
          // Google docs wraps the the content inside the <b></b> tag.
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
    if (delta.operations.isNotEmpty) {
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
      if (delta.operations.isNotEmpty) {
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

  Attributes? _getDeltaAttributesFromHtmlAttributes(
      LinkedHashMap<Object, String> htmlAttributes) {
    final attrs = <String, dynamic>{};
    final styleString = htmlAttributes["style"];
    if (styleString != null) {
      final entries = styleString.split(";");
      for (final entry in entries) {
        final tuples = entry.split(":");
        if (tuples.length < 2) {
          continue;
        }
        if (tuples[0] == "font-weight") {
          int? weight = int.tryParse(tuples[1]);
          if (weight != null && weight > 500) {
            attrs["bold"] = true;
          }
        }
      }
    }

    return attrs.isEmpty ? null : attrs;
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
      delta.insert(element.text, {"bold": true});
    } else {
      delta.insert(element.text);
    }
  }

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

class NodesToHTMLConverter {
  final List<Node> nodes;
  final int? startOffset;
  final int? endOffset;
  final List<html.Node> _result = [];
  html.Element? _stashListContainer;

  NodesToHTMLConverter({required this.nodes, this.startOffset, this.endOffset});

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

    for (final op in delta.operations) {
      if (op is TextInsert) {
        final attributes = op.attributes;
        if (attributes != null && attributes[StyleKey.bold] == true) {
          final strong = html.Element.tag("strong");
          strong.append(html.Text(op.content));
          childNodes.add(strong);
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
