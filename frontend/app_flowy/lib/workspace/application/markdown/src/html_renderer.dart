// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ast.dart';
import 'block_parser.dart';
import 'document.dart';
import 'extension_set.dart';
import 'inline_parser.dart';

/// Converts the given string of Markdown to HTML.
String markdownToHtml(String markdown,
    {Iterable<BlockSyntax>? blockSyntaxes,
    Iterable<InlineSyntax>? inlineSyntaxes,
    ExtensionSet? extensionSet,
    Resolver? linkResolver,
    Resolver? imageLinkResolver,
    bool inlineOnly = false}) {
  final document = Document(
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
      extensionSet: extensionSet,
      linkResolver: linkResolver,
      imageLinkResolver: imageLinkResolver);

  if (inlineOnly) {
    return renderToHtml(document.parseInline(markdown)!);
  }

  // Replace windows line endings with unix line endings, and split.
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');

  return '${renderToHtml(document.parseLines(lines))}\n';
}

/// Renders [nodes] to HTML.
String renderToHtml(List<Node> nodes) => HtmlRenderer().render(nodes);

/// Translates a parsed AST to HTML.
class HtmlRenderer implements NodeVisitor {
  HtmlRenderer();

  static final _blockTags = RegExp('blockquote|h1|h2|h3|h4|h5|h6|hr|p|pre');

  late StringBuffer buffer;
  late Set<String> uniqueIds;

  String render(List<Node> nodes) {
    buffer = StringBuffer();
    uniqueIds = <String>{};

    for (final node in nodes) {
      node.accept(this);
    }

    return buffer.toString();
  }

  @override
  void visitText(Text text) {
    buffer.write(text.text);
  }

  @override
  bool visitElementBefore(Element element) {
    // Hackish. Separate block-level elements with newlines.
    if (buffer.isNotEmpty && _blockTags.firstMatch(element.tag) != null) {
      buffer.write('\n');
    }

    buffer.write('<${element.tag}');

    // Sort the keys so that we generate stable output.
    final attributeNames = element.attributes.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    for (final name in attributeNames) {
      buffer.write(' $name="${element.attributes[name]}"');
    }

    // attach header anchor ids generated from text
    if (element.generatedId != null) {
      buffer.write(' id="${uniquifyId(element.generatedId!)}"');
    }

    if (element.isEmpty) {
      // Empty element like <hr/>.
      buffer.write(' />');

      if (element.tag == 'br') {
        buffer.write('\n');
      }

      return false;
    } else {
      buffer.write('>');
      return true;
    }
  }

  @override
  void visitElementAfter(Element element) {
    buffer.write('</${element.tag}>');
  }

  /// Uniquifies an id generated from text.
  String uniquifyId(String id) {
    if (!uniqueIds.contains(id)) {
      uniqueIds.add(id);
      return id;
    }

    var suffix = 2;
    var suffixedId = '$id-$suffix';
    while (uniqueIds.contains(suffixedId)) {
      suffixedId = '$id-${suffix++}';
    }
    uniqueIds.add(suffixedId);
    return suffixedId;
  }
}
