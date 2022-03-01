// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Resolver = Node? Function(String name, [String? title]);

/// Base class for any AST item.
///
/// Roughly corresponds to Node in the DOM. Will be either an Element or Text.
class Node {
  void accept(NodeVisitor visitor) {}

  bool isToplevel = false;

  String? get textContent {
    return null;
  }
}

/// A named tag that can contain other nodes.
class Element extends Node {
  /// Instantiates a [tag] Element with [children].
  Element(this.tag, this.children) : attributes = <String, String>{};

  /// Instantiates an empty, self-closing [tag] Element.
  Element.empty(this.tag)
      : children = null,
        attributes = {};

  /// Instantiates a [tag] Element with no [children].
  Element.withTag(this.tag)
      : children = [],
        attributes = {};

  /// Instantiates a [tag] Element with a single Text child.
  Element.text(this.tag, String text)
      : children = [Text(text)],
        attributes = {};

  final String tag;
  final List<Node>? children;
  final Map<String, String> attributes;
  String? generatedId;

  /// Whether this element is self-closing.
  bool get isEmpty => children == null;

  @override
  void accept(NodeVisitor visitor) {
    if (visitor.visitElementBefore(this)) {
      if (children != null) {
        for (final child in children!) {
          child.accept(visitor);
        }
      }
      visitor.visitElementAfter(this);
    }
  }

  @override
  String get textContent => children == null
      ? ''
      : children!.map((child) => child.textContent).join();
}

/// A plain text element.
class Text extends Node {
  Text(this.text);

  final String text;

  @override
  void accept(NodeVisitor visitor) => visitor.visitText(this);

  @override
  String get textContent => text;
}

/// Inline content that has not been parsed into inline nodes (strong, links,
/// etc).
///
/// These placeholder nodes should only remain in place while the block nodes
/// of a document are still being parsed, in order to gather all reference link
/// definitions.
class UnparsedContent extends Node {
  UnparsedContent(this.textContent);

  @override
  final String textContent;

  @override
  void accept(NodeVisitor visitor);
}

/// Visitor pattern for the AST.
///
/// Renderers or other AST transformers should implement this.
abstract class NodeVisitor {
  /// Called when a Text node has been reached.
  void visitText(Text text);

  /// Called when an Element has been reached, before its children have been
  /// visited.
  ///
  /// Returns `false` to skip its children.
  bool visitElementBefore(Element element);

  /// Called when an Element has been reached, after its children have been
  /// visited.
  ///
  /// Will not be called if [visitElementBefore] returns `false`.
  void visitElementAfter(Element element);
}
