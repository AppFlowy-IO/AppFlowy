import 'dart:collection';

import 'package:flowy_editor/document/attributes.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flutter/foundation.dart';
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

class HTMLConverter {
  final html.Document _document;

  HTMLConverter(String htmlString) : _document = parse(htmlString);

  List<Node> toNodes() {
    final result = <Node>[];
    final delta = Delta();

    final childNodes = _document.body?.nodes.toList() ?? <html.Node>[];
    for (final child in childNodes) {
      if (child is html.Element) {
        if (child.localName == tagAnchor ||
            child.localName == tagSpan ||
            child.localName == tagStrong ||
            child.localName == tagBold) {
          _handleRichTextElement(delta, child);
        } else {
          _handleElement(result, child);
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

  _handleElement(List<Node> nodes, html.Element element) {
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
      _handleParagraph(nodes, element);
    } else {
      final delta = Delta();
      delta.insert(element.text);
      if (delta.operations.isNotEmpty) {
        nodes.add(TextNode(type: "text", delta: delta));
      }
    }
  }

  _handleParagraph(List<Node> nodes, html.Element element) {
    _handleRichText(nodes, element);
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

  _handleRichText(List<Node> nodes, html.Element element) {
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
      nodes.add(TextNode(type: "text", delta: delta));
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
        _handleRichText(nodes, child);
      }
    }
  }
}

String deltaToHtml(Delta delta) {
  var result = "<p>";

  for (final op in delta.operations) {
    if (op is TextInsert) {
      final attributes = op.attributes;
      if (attributes != null && attributes["bold"] == true) {
        result += '<strong>${op.content}</strong>';
      } else {
        result += op.content;
      }
    }
  }

  result += "</p>";
  return result;
}
