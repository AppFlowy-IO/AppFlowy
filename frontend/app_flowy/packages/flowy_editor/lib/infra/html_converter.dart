import 'dart:collection';

import 'package:flowy_editor/document/attributes.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html;

const String tagH1 = "h1";
const String tagH2 = "h2";
const String tagH3 = "h3";
const String tagUnorderedList = "ul";
const String tagList = "li";
const String tagParagraph = "p";
const String tagImage = "img";
const String tagAnchor = "a";
const String tagBold = "b";
const String tagStrong = "strong";
const String tagSpan = "span";
const String tagCode = "code";

class HTMLConverter {
  final html.Document _document;
  bool _inParagraph = false;

  HTMLConverter(String htmlString) : _document = parse(htmlString);

  List<Node> toNodes() {
    final result = <Node>[];

    final childNodes = _document.body?.nodes.toList() ?? <html.Node>[];
    _handleContainer(result, childNodes);

    return result;
  }

  _handleContainer(List<Node> nodes, List<html.Node> childNodes) {
    final delta = Delta();
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
            _handleBTag(nodes, child);
          } else {
            _handleRichText(nodes, child);
          }
        } else {
          _handleElement(nodes, child);
        }
      } else {
        delta.insert(child.text ?? "");
      }
    }
    if (delta.operations.isNotEmpty) {
      nodes.add(TextNode(type: "text", delta: delta));
    }
  }

  _handleBTag(List<Node> nodes, html.Element element) {
    final childNodes = element.nodes;
    _handleContainer(nodes, childNodes);
  }

  _handleElement(List<Node> nodes, html.Element element,
      [Map<String, dynamic>? attributes]) {
    if (element.localName == tagH1) {
      _handleHeadingElement(nodes, element, tagH1);
    } else if (element.localName == tagH2) {
      _handleHeadingElement(nodes, element, tagH2);
    } else if (element.localName == tagH3) {
      _handleHeadingElement(nodes, element, tagH3);
    } else if (element.localName == tagUnorderedList) {
      _handleUnorderedList(nodes, element);
    } else if (element.localName == tagList) {
      _handleListElement(nodes, element);
    } else if (element.localName == tagParagraph) {
      _handleParagraph(nodes, element, attributes);
    } else {
      final delta = Delta();
      delta.insert(element.text);
      if (delta.operations.isNotEmpty) {
        nodes.add(TextNode(type: "text", delta: delta));
      }
    }
  }

  _handleParagraph(List<Node> nodes, html.Element element,
      [Map<String, dynamic>? attributes]) {
    _inParagraph = true;
    _handleRichText(nodes, element, attributes);
    _inParagraph = false;
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

  _handleRichText(List<Node> nodes, html.Element element,
      [Map<String, dynamic>? attributes]) {
    final image = element.querySelector(tagImage);
    if (image != null) {
      _handleImage(nodes, image);
      return;
    }

    var delta = Delta();

    for (final child in element.nodes.toList()) {
      if (child is html.Element) {
        _handleRichTextElement(delta, child);
      } else {
        delta.insert(child.text ?? "");
      }
    }

    if (delta.operations.isNotEmpty) {
      nodes.add(TextNode(type: "text", delta: delta, attributes: attributes));
    }
  }

  _handleImage(List<Node> nodes, html.Element element) {
    final src = element.attributes["src"];
    final attributes = <String, dynamic>{};
    if (src != null) {
      attributes["image_src"] = src;
    }
    debugPrint("insert image: $src");
    nodes.add(
        Node(type: "image", attributes: attributes, children: LinkedList()));
  }

  _handleUnorderedList(List<Node> nodes, html.Element element) {
    element.children.forEach((child) {
      _handleListElement(nodes, child);
    });
  }

  _handleHeadingElement(
    List<Node> nodes,
    html.Element element,
    String headingStyle,
  ) {
    final delta = Delta();
    delta.insert(element.text);
    if (delta.operations.isNotEmpty) {
      nodes.add(TextNode(
          type: "text",
          attributes: {"subtype": "heading", "heading": headingStyle},
          delta: delta));
    }
  }

  _handleListElement(List<Node> nodes, html.Element element) {
    final childNodes = element.nodes.toList();
    for (final child in childNodes) {
      if (child is html.Element) {
        _handleElement(nodes, child, {"subtype": "bulleted-list"});
      }
    }
  }
}

html.Element deltaToHtml(Delta delta, [String? subType]) {
  final childNodes = <html.Node>[];
  String tagName = tagParagraph;

  if (subType == "bulleted-list") {
    tagName = tagList;
  }

  for (final op in delta.operations) {
    if (op is TextInsert) {
      final attributes = op.attributes;
      if (attributes != null && attributes["bold"] == true) {
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
    final result = html.Element.tag("li");
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

String stringify(html.Node node) {
  if (node is html.Element) {
    String result = '<${node.localName}>';

    for (final node in node.nodes) {
      result += stringify(node);
    }

    return result += '</${node.localName}>';
  }

  if (node is html.Text) {
    return node.text;
  }

  return "";
}
