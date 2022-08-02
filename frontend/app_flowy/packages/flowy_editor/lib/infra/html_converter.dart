import 'dart:collection';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html;

class HTMLConverter {
  final html.Document _document;

  HTMLConverter(String htmlString) : _document = parse(htmlString);

  List<Node> toNodes() {
    final result = <Node>[];
    final delta = Delta();

    for (final child in _document.body?.nodes.toList() ?? <html.Node>[]) {
      if (child is html.Element) {
        if (child.localName == "span") {
          delta.insert(child.text);
        } else if (child.localName == "strong") {
          delta.insert(child.text, {"bold": true});
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
    if (element.localName == "h1") {
      _handleHeadingElement(nodes, element, "h1");
    } else if (element.localName == "h2") {
      _handleHeadingElement(nodes, element, "h2");
    } else if (element.localName == "h3") {
      _handleHeadingElement(nodes, element, "h3");
    } else if (element.localName == "ul") {
      _handleUnorderedList(nodes, element);
    } else if (element.localName == "li") {
      _handleListElement(nodes, element);
    } else if (element.localName == "p") {
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
    final image = element.querySelector("img");
    if (image != null) {
      _handleImage(nodes, image);
      return;
    }

    var delta = Delta();

    for (final child in element.nodes.toList()) {
      if (child is html.Element) {
        if (child.localName == "a") {
          final hyperLink = child.attributes["href"];
          Map<String, dynamic>? attributes;
          if (hyperLink != null) {
            attributes = {"href": hyperLink};
          }
          delta.insert(child.text, attributes);
        } else {
          delta.insert(child.text);
        }
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
    final delta = Delta();
    delta.insert(element.text);
    if (delta.operations.isNotEmpty) {
      nodes.add(TextNode(
          type: "text", attributes: {"subtype": "bullet-list"}, delta: delta));
    }
  }
}
