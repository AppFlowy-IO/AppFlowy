import 'dart:collection';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html;

class HTMLConverter {
  final html.Document _document;

  HTMLConverter(String htmlString) : _document = parse(htmlString);

  List<Node> toNodes() {
    final result = <Node>[];

    final bodyChildren = _document.body?.children ?? [];
    for (final child in bodyChildren) {
      _handleElement(result, child);
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
    for (final child in element.children) {
      if (child.localName == "a") {
        _handleAnchorLink(nodes, child);
      }
    }

    final delta = Delta();
    delta.insert(element.text);
    if (delta.operations.isNotEmpty) {
      nodes.add(TextNode(type: "text", delta: delta));
    }
  }

  _handleAnchorLink(List<Node> nodes, html.Element element) {
    for (final child in element.children) {
      if (child.localName == "img") {
        _handleImage(nodes, child);
        return;
      }
    }
  }

  _handleImage(List<Node> nodes, html.Element element) {
    final src = element.attributes["src"];
    final attributes = <String, dynamic>{};
    if (src != null) {
      attributes["image_src"] = src;
    }
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
