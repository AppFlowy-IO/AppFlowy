// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ast.dart';
import 'document.dart';
import 'util.dart';

/// The line contains only whitespace or is empty.
final _emptyPattern = RegExp(r'^(?:[ \t]*)$');

/// A series of `=` or `-` (on the next line) define setext-style headers.
final _setextPattern = RegExp(r'^[ ]{0,3}(=+|-+)\s*$');

/// Leading (and trailing) `#` define atx-style headers.
///
/// Starts with 1-6 unescaped `#` characters which must not be followed by a
/// non-space character. Line may end with any number of `#` characters,.
final _headerPattern = RegExp(r'^ {0,3}(#{1,6})[ \x09\x0b\x0c](.*?)#*$');

/// The line starts with `>` with one optional space after.
final _blockquotePattern = RegExp(r'^[ ]{0,3}>[ ]?(.*)$');

/// A line indented four spaces. Used for code blocks and lists.
final _indentPattern = RegExp(r'^(?:    | {0,3}\t)(.*)$');

/// Fenced code block.
final _codePattern = RegExp(r'^[ ]{0,3}(`{3,}|~{3,})(.*)$');

/// Three or more hyphens, asterisks or underscores by themselves. Note that
/// a line like `----` is valid as both HR and SETEXT. In case of a tie,
/// SETEXT should win.
final _hrPattern = RegExp(r'^ {0,3}([-*_])[ \t]*\1[ \t]*\1(?:\1|[ \t])*$');

/// One or more whitespace, for compressing.
final _oneOrMoreWhitespacePattern = RegExp('[ \n\r\t]+');

/// A line starting with one of these markers: `-`, `*`, `+`. May have up to
/// three leading spaces before the marker and any number of spaces or tabs
/// after.
///
/// Contains a dummy group at [2], so that the groups in [_ulPattern] and
/// [_olPattern] match up; in both, [2] is the length of the number that begins
/// the list marker.
final _ulPattern = RegExp(r'^([ ]{0,3})()([*+-])(([ \t])([ \t]*)(.*))?$');

/// A line starting with a number like `123.`. May have up to three leading
/// spaces before the marker and any number of spaces or tabs after.
final _olPattern =
    RegExp(r'^([ ]{0,3})(\d{1,9})([\.)])(([ \t])([ \t]*)(.*))?$');

/// A line of hyphens separated by at least one pipe.
final _tablePattern = RegExp(r'^[ ]{0,3}\|?( *:?\-+:? *\|)+( *:?\-+:? *)?$');

/// Maintains the internal state needed to parse a series of lines into blocks
/// of Markdown suitable for further inline parsing.
class BlockParser {
  BlockParser(this.lines, this.document) {
    blockSyntaxes
      ..addAll(document.blockSyntaxes)
      ..addAll(standardBlockSyntaxes);
  }

  final List<String> lines;

  /// The Markdown document this parser is parsing.
  final Document document;

  /// The enabled block syntaxes.
  ///
  /// To turn a series of lines into blocks, each of these will be tried in
  /// turn. Order matters here.
  final List<BlockSyntax> blockSyntaxes = [];

  /// Index of the current line.
  int _pos = 0;

  /// Whether the parser has encountered a blank line between two block-level
  /// elements.
  bool encounteredBlankLine = false;

  /// The collection of built-in block parsers.
  final List<BlockSyntax> standardBlockSyntaxes = [
    const EmptyBlockSyntax(),
    const BlockTagBlockHtmlSyntax(),
    LongBlockHtmlSyntax(r'^ {0,3}<pre(?:\s|>|$)', '</pre>'),
    LongBlockHtmlSyntax(r'^ {0,3}<script(?:\s|>|$)', '</script>'),
    LongBlockHtmlSyntax(r'^ {0,3}<style(?:\s|>|$)', '</style>'),
    LongBlockHtmlSyntax('^ {0,3}<!--', '-->'),
    LongBlockHtmlSyntax('^ {0,3}<\\?', '\\?>'),
    LongBlockHtmlSyntax('^ {0,3}<![A-Z]', '>'),
    LongBlockHtmlSyntax('^ {0,3}<!\\[CDATA\\[', '\\]\\]>'),
    const OtherTagBlockHtmlSyntax(),
    const SetextHeaderSyntax(),
    const HeaderSyntax(),
    const CodeBlockSyntax(),
    const BlockquoteSyntax(),
    const HorizontalRuleSyntax(),
    const UnorderedListSyntax(),
    const OrderedListSyntax(),
    const ParagraphSyntax()
  ];

  /// Gets the current line.
  String get current => lines[_pos];

  /// Gets the line after the current one or `null` if there is none.
  String? get next {
    // Don't read past the end.
    if (_pos >= lines.length - 1) {
      return null;
    }
    return lines[_pos + 1];
  }

  /// Gets the line that is [linesAhead] lines ahead of the current one, or
  /// `null` if there is none.
  ///
  /// `peek(0)` is equivalent to [current].
  ///
  /// `peek(1)` is equivalent to [next].
  String? peek(int linesAhead) {
    if (linesAhead < 0) {
      throw ArgumentError('Invalid linesAhead: $linesAhead; must be >= 0.');
    }
    // Don't read past the end.
    if (_pos >= lines.length - linesAhead) {
      return null;
    }
    return lines[_pos + linesAhead];
  }

  void advance() {
    _pos++;
  }

  bool get isDone => _pos >= lines.length;

  /// Gets whether or not the current line matches the given pattern.
  bool matches(RegExp regex) {
    if (isDone) {
      return false;
    }
    return regex.firstMatch(current) != null;
  }

  /// Gets whether or not the next line matches the given pattern.
  bool matchesNext(RegExp regex) {
    if (next == null) {
      return false;
    }
    return regex.firstMatch(next!) != null;
  }

  List<Node> parseLines() {
    final blocks = <Node>[];
    while (!isDone) {
      for (final syntax in blockSyntaxes) {
        if (syntax.canParse(this)) {
          final block = syntax.parse(this);
          if (block != null) {
            blocks.add(block);
          }
          break;
        }
      }
    }

    return blocks;
  }
}

abstract class BlockSyntax {
  const BlockSyntax();

  /// Gets the regex used to identify the beginning of this block, if any.
  RegExp? get pattern => null;

  bool get canEndBlock => true;

  bool canParse(BlockParser parser) {
    return pattern!.firstMatch(parser.current) != null;
  }

  Node? parse(BlockParser parser);

  List<String?> parseChildLines(BlockParser parser) {
    // Grab all of the lines that form the block element.
    final childLines = <String?>[];

    while (!parser.isDone) {
      final match = pattern!.firstMatch(parser.current);
      if (match == null) {
        break;
      }
      childLines.add(match[1]);
      parser.advance();
    }

    return childLines;
  }

  /// Gets whether or not [parser]'s current line should end the previous block.
  static bool isAtBlockEnd(BlockParser parser) {
    if (parser.isDone) {
      return true;
    }
    return parser.blockSyntaxes.any((s) => s.canParse(parser) && s.canEndBlock);
  }

  /// Generates a valid HTML anchor from the inner text of [element].
  static String generateAnchorHash(Element element) =>
      element.children!.first.textContent!
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
          .replaceAll(RegExp(r'\s'), '-');
}

class EmptyBlockSyntax extends BlockSyntax {
  const EmptyBlockSyntax();

  @override
  RegExp get pattern => _emptyPattern;

  @override
  Node? parse(BlockParser parser) {
    parser
      ..encounteredBlankLine = true
      ..advance();

    // Don't actually emit anything.
    return null;
  }
}

/// Parses setext-style headers.
class SetextHeaderSyntax extends BlockSyntax {
  const SetextHeaderSyntax();

  @override
  bool canParse(BlockParser parser) {
    if (!_interperableAsParagraph(parser.current)) {
      return false;
    }

    var i = 1;
    while (true) {
      final nextLine = parser.peek(i);
      if (nextLine == null) {
        // We never reached an underline.
        return false;
      }
      if (_setextPattern.hasMatch(nextLine)) {
        return true;
      }
      // Ensure that we're still in something like paragraph text.
      if (!_interperableAsParagraph(nextLine)) {
        return false;
      }
      i++;
    }
  }

  @override
  Node parse(BlockParser parser) {
    final lines = <String>[];
    late String tag;
    while (!parser.isDone) {
      final match = _setextPattern.firstMatch(parser.current);
      if (match == null) {
        // More text.
        lines.add(parser.current);
        parser.advance();
        continue;
      } else {
        // The underline.
        tag = (match[1]![0] == '=') ? 'h1' : 'h2';
        parser.advance();
        break;
      }
    }

    final contents = UnparsedContent(lines.join('\n'));

    return Element(tag, [contents]);
  }

  bool _interperableAsParagraph(String line) =>
      !(_indentPattern.hasMatch(line) ||
          _codePattern.hasMatch(line) ||
          _headerPattern.hasMatch(line) ||
          _blockquotePattern.hasMatch(line) ||
          _hrPattern.hasMatch(line) ||
          _ulPattern.hasMatch(line) ||
          _olPattern.hasMatch(line) ||
          _emptyPattern.hasMatch(line));
}

/// Parses setext-style headers, and adds generated IDs to the generated
/// elements.
class SetextHeaderWithIdSyntax extends SetextHeaderSyntax {
  const SetextHeaderWithIdSyntax();

  @override
  Node parse(BlockParser parser) {
    final element = super.parse(parser) as Element;
    element.generatedId = BlockSyntax.generateAnchorHash(element);
    return element;
  }
}

/// Parses atx-style headers: `## Header ##`.
class HeaderSyntax extends BlockSyntax {
  const HeaderSyntax();

  @override
  RegExp get pattern => _headerPattern;

  @override
  Node parse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current)!;
    parser.advance();
    final level = match[1]!.length;
    final contents = UnparsedContent(match[2]!.trim());
    return Element('h$level', [contents]);
  }
}

/// Parses atx-style headers, and adds generated IDs to the generated elements.
class HeaderWithIdSyntax extends HeaderSyntax {
  const HeaderWithIdSyntax();

  @override
  Node parse(BlockParser parser) {
    final element = super.parse(parser) as Element;
    element.generatedId = BlockSyntax.generateAnchorHash(element);
    return element;
  }
}

/// Parses email-style blockquotes: `> quote`.
class BlockquoteSyntax extends BlockSyntax {
  const BlockquoteSyntax();

  @override
  RegExp get pattern => _blockquotePattern;

  @override
  List<String> parseChildLines(BlockParser parser) {
    // Grab all of the lines that form the blockquote, stripping off the ">".
    final childLines = <String>[];

    while (!parser.isDone) {
      final match = pattern.firstMatch(parser.current);
      if (match != null) {
        childLines.add(match[1]!);
        parser.advance();
        continue;
      }

      // A paragraph continuation is OK. This is content that cannot be parsed
      // as any other syntax except Paragraph, and it doesn't match the bar in
      // a Setext header.
      if (parser.blockSyntaxes.firstWhere((s) => s.canParse(parser))
          is ParagraphSyntax) {
        childLines.add(parser.current);
        parser.advance();
      } else {
        break;
      }
    }

    return childLines;
  }

  @override
  Node parse(BlockParser parser) {
    final childLines = parseChildLines(parser);

    // Recursively parse the contents of the blockquote.
    final children = BlockParser(childLines, parser.document).parseLines();
    return Element('blockquote', children);
  }
}

/// Parses preformatted code blocks that are indented four spaces.
class CodeBlockSyntax extends BlockSyntax {
  const CodeBlockSyntax();

  @override
  RegExp get pattern => _indentPattern;

  @override
  bool get canEndBlock => false;

  @override
  List<String?> parseChildLines(BlockParser parser) {
    final childLines = <String?>[];

    while (!parser.isDone) {
      final match = pattern.firstMatch(parser.current);
      if (match != null) {
        childLines.add(match[1]);
        parser.advance();
      } else {
        // If there's a codeblock, then a newline, then a codeblock, keep the
        // code blocks together.
        final nextMatch =
            parser.next != null ? pattern.firstMatch(parser.next!) : null;
        if (parser.current.trim() == '' && nextMatch != null) {
          childLines..add('')..add(nextMatch[1]);
          parser..advance()..advance();
        } else {
          break;
        }
      }
    }
    return childLines;
  }

  @override
  Node parse(BlockParser parser) {
    final childLines = parseChildLines(parser)
      // The Markdown tests expect a trailing newline.
      ..add('');

    // Escape the code.
    final escaped = escapeHtml(childLines.join('\n'));

    return Element('pre', [Element.text('code', escaped)]);
  }
}

/// Parses preformatted code blocks between two ~~~ or ``` sequences.
///
/// See [Pandoc's documentation](http://pandoc.org/README.html#fenced-code-blocks).
class FencedCodeBlockSyntax extends BlockSyntax {
  const FencedCodeBlockSyntax();

  @override
  RegExp get pattern => _codePattern;

  @override
  List<String> parseChildLines(BlockParser parser, [String? endBlock]) {
    endBlock ??= '';

    final childLines = <String>[];
    parser.advance();

    while (!parser.isDone) {
      final match = pattern.firstMatch(parser.current);
      if (match == null || !match[1]!.startsWith(endBlock)) {
        childLines.add(parser.current);
        parser.advance();
      } else {
        parser.advance();
        break;
      }
    }

    return childLines;
  }

  @override
  Node parse(BlockParser parser) {
    // Get the syntax identifier, if there is one.
    final match = pattern.firstMatch(parser.current)!;
    final endBlock = match.group(1);
    var infoString = match.group(2)!;

    final childLines = parseChildLines(parser, endBlock)
      // The Markdown tests expect a trailing newline.
      ..add('');

    final code = Element.text('code', childLines.join('\n'));

    // the info-string should be trimmed
    // http://spec.commonmark.org/0.22/#example-100
    infoString = infoString.trim();
    if (infoString.isNotEmpty) {
      // only use the first word in the syntax
      // http://spec.commonmark.org/0.22/#example-100
      infoString = infoString.split(' ').first;
      code.attributes['class'] = 'language-$infoString';
    }

    final element = Element('pre', [code]);
    return element;
  }
}

/// Parses horizontal rules like `---`, `_ _ _`, `*  *  *`, etc.
class HorizontalRuleSyntax extends BlockSyntax {
  const HorizontalRuleSyntax();

  @override
  RegExp get pattern => _hrPattern;

  @override
  Node parse(BlockParser parser) {
    parser.advance();
    return Element.empty('hr');
  }
}

/// Parses inline HTML at the block level. This differs from other Markdown
/// implementations in several ways:
///
/// 1.  This one is way way WAY simpler.
/// 2.  Essentially no HTML parsing or validation is done. We're a Markdown
///     parser, not an HTML parser!
abstract class BlockHtmlSyntax extends BlockSyntax {
  const BlockHtmlSyntax();

  @override
  bool get canEndBlock => true;
}

class BlockTagBlockHtmlSyntax extends BlockHtmlSyntax {
  const BlockTagBlockHtmlSyntax();

  static final _pattern = RegExp(
      r'^ {0,3}</?(?:address|article|aside|base|basefont|blockquote|body|'
      r'caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|'
      r'figcaption|figure|footer|form|frame|frameset|h1|head|header|hr|html|'
      r'iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|'
      r'option|p|param|section|source|summary|table|tbody|td|tfoot|th|thead|'
      'title|tr|track|ul)'
      r'(?:\s|>|/>|$)');

  @override
  RegExp get pattern => _pattern;

  @override
  Node parse(BlockParser parser) {
    final childLines = <String>[];

    // Eat until we hit a blank line.
    while (!parser.isDone && !parser.matches(_emptyPattern)) {
      childLines.add(parser.current);
      parser.advance();
    }

    return Text(childLines.join('\n'));
  }
}

class OtherTagBlockHtmlSyntax extends BlockTagBlockHtmlSyntax {
  const OtherTagBlockHtmlSyntax();

  @override
  bool get canEndBlock => false;

  // Really hacky way to detect "other" HTML. This matches:
  //
  // * any opening spaces
  // * open bracket and maybe a slash ("<" or "</")
  // * some word characters
  // * either:
  //   * a close bracket, or
  //   * whitespace followed by not-brackets followed by a close bracket
  // * possible whitespace and the end of the line.
  @override
  RegExp get pattern => RegExp(r'^ {0,3}</?\w+(?:>|\s+[^>]*>)\s*$');
}

/// A BlockHtmlSyntax that has a specific `endPattern`.
///
/// In practice this means that the syntax dominates; it is allowed to eat
/// many lines, including blank lines, before matching its `endPattern`.
class LongBlockHtmlSyntax extends BlockHtmlSyntax {
  LongBlockHtmlSyntax(String pattern, String endPattern)
      : pattern = RegExp(pattern),
        _endPattern = RegExp(endPattern);

  @override
  final RegExp pattern;
  final RegExp _endPattern;

  @override
  Node parse(BlockParser parser) {
    final childLines = <String>[];
    // Eat until we hit [endPattern].
    while (!parser.isDone) {
      childLines.add(parser.current);
      if (parser.matches(_endPattern)) {
        break;
      }
      parser.advance();
    }

    parser.advance();
    return Text(childLines.join('\n'));
  }
}

class ListItem {
  ListItem(this.lines);

  bool forceBlock = false;
  final List<String> lines;
}

/// Base class for both ordered and unordered lists.
abstract class ListSyntax extends BlockSyntax {
  const ListSyntax();

  @override
  bool get canEndBlock => true;

  String get listTag;

  /// A list of patterns that can start a valid block within a list item.
  static final blocksInList = [
    _blockquotePattern,
    _headerPattern,
    _hrPattern,
    _indentPattern,
    _ulPattern,
    _olPattern
  ];

  static final _whitespaceRe = RegExp('[ \t]*');

  @override
  Node parse(BlockParser parser) {
    final items = <ListItem>[];
    var childLines = <String>[];

    void endItem() {
      if (childLines.isNotEmpty) {
        items.add(ListItem(childLines));
        childLines = <String>[];
      }
    }

    Match? match;
    bool tryMatch(RegExp pattern) {
      match = pattern.firstMatch(parser.current);
      return match != null;
    }

    String? listMarker;
    String? indent;
    // In case the first number in an ordered list is not 1, use it as the
    // "start".
    int? startNumber;

    while (!parser.isDone) {
      final leadingSpace =
          _whitespaceRe.matchAsPrefix(parser.current)!.group(0)!;
      final leadingExpandedTabLength = _expandedTabLength(leadingSpace);
      if (tryMatch(_emptyPattern)) {
        if (_emptyPattern.firstMatch(parser.next ?? '') != null) {
          // Two blank lines ends a list.
          break;
        }
        // Add a blank line to the current list item.
        childLines.add('');
      } else if (indent != null && indent.length <= leadingExpandedTabLength) {
        // Strip off indent and add to current item.
        final line = parser.current
            .replaceFirst(leadingSpace, ' ' * leadingExpandedTabLength)
            .replaceFirst(indent, '');
        childLines.add(line);
      } else if (tryMatch(_hrPattern)) {
        // Horizontal rule takes precedence to a list item.
        break;
      } else if (tryMatch(_ulPattern) || tryMatch(_olPattern)) {
        final precedingWhitespace = match![1];
        final digits = match![2] ?? '';
        if (startNumber == null && digits.isNotEmpty) {
          startNumber = int.parse(digits);
        }
        final marker = match![3];
        final firstWhitespace = match![5] ?? '';
        final restWhitespace = match![6] ?? '';
        final content = match![7] ?? '';
        final isBlank = content.isEmpty;
        if (listMarker != null && listMarker != marker) {
          // Changing the bullet or ordered list delimiter starts a list.
          break;
        }
        listMarker = marker;
        final markerAsSpaces = ' ' * (digits.length + marker!.length);
        if (isBlank) {
          // See http://spec.commonmark.org/0.28/#list-items under "3. Item
          // starting with a blank line."
          //
          // If the list item starts with a blank line, the final piece of the
          // indentation is just a single space.
          indent = '$precedingWhitespace$markerAsSpaces ';
        } else if (restWhitespace.length >= 4) {
          // See http://spec.commonmark.org/0.28/#list-items under "2. Item
          // starting with indented code."
          //
          // If the list item starts with indented code, we need to _not_ count
          // any indentation past the required whitespace character.
          indent = precedingWhitespace! + markerAsSpaces + firstWhitespace;
        } else {
          indent = precedingWhitespace! +
              markerAsSpaces +
              firstWhitespace +
              restWhitespace;
        }
        // End the current list item and start a one.
        endItem();
        childLines.add(restWhitespace + content);
      } else if (BlockSyntax.isAtBlockEnd(parser)) {
        // Done with the list.
        break;
      } else {
        // If the previous item is a blank line, this means we're done with the
        // list and are starting a top-level paragraph.
        if ((childLines.isNotEmpty) && (childLines.last == '')) {
          parser.encounteredBlankLine = true;
          break;
        }

        // Anything else is paragraph continuation text.
        childLines.add(parser.current);
      }
      parser.advance();
    }

    endItem();
    final itemNodes = <Element>[];

    items.forEach(removeLeadingEmptyLine);
    final anyEmptyLines = removeTrailingEmptyLines(items);
    var anyEmptyLinesBetweenBlocks = false;

    for (final item in items) {
      final itemParser = BlockParser(item.lines, parser.document);
      final children = itemParser.parseLines();
      itemNodes.add(Element('li', children));
      anyEmptyLinesBetweenBlocks =
          anyEmptyLinesBetweenBlocks || itemParser.encounteredBlankLine;
    }

    // Must strip paragraph tags if the list is "tight".
    // http://spec.commonmark.org/0.28/#lists
    final listIsTight = !anyEmptyLines && !anyEmptyLinesBetweenBlocks;

    if (listIsTight) {
      // We must post-process the list items, converting any top-level paragraph
      // elements to just text elements.
      for (final item in itemNodes) {
        for (var i = 0; i < item.children!.length; i++) {
          final child = item.children![i];
          if (child is Element && child.tag == 'p') {
            item.children!.removeAt(i);
            item.children!.insertAll(i, child.children!);
          }
        }
      }
    }

    if (listTag == 'ol' && startNumber != 1) {
      return Element(listTag, itemNodes)..attributes['start'] = '$startNumber';
    } else {
      return Element(listTag, itemNodes);
    }
  }

  void removeLeadingEmptyLine(ListItem item) {
    if (item.lines.isNotEmpty && _emptyPattern.hasMatch(item.lines.first)) {
      item.lines.removeAt(0);
    }
  }

  /// Removes any trailing empty lines and notes whether any items are separated
  /// by such lines.
  bool removeTrailingEmptyLines(List<ListItem> items) {
    var anyEmpty = false;
    for (var i = 0; i < items.length; i++) {
      if (items[i].lines.length == 1) {
        continue;
      }
      while (items[i].lines.isNotEmpty &&
          _emptyPattern.hasMatch(items[i].lines.last)) {
        if (i < items.length - 1) {
          anyEmpty = true;
        }
        items[i].lines.removeLast();
      }
    }
    return anyEmpty;
  }

  static int _expandedTabLength(String input) {
    var length = 0;
    for (final char in input.codeUnits) {
      length += char == 0x9 ? 4 - (length % 4) : 1;
    }
    return length;
  }
}

/// Parses unordered lists.
class UnorderedListSyntax extends ListSyntax {
  const UnorderedListSyntax();

  @override
  RegExp get pattern => _ulPattern;

  @override
  String get listTag => 'ul';
}

/// Parses ordered lists.
class OrderedListSyntax extends ListSyntax {
  const OrderedListSyntax();

  @override
  RegExp get pattern => _olPattern;

  @override
  String get listTag => 'ol';
}

/// Parses tables.
class TableSyntax extends BlockSyntax {
  const TableSyntax();

  static final _pipePattern = RegExp(r'\s*\|\s*');
  static final _openingPipe = RegExp(r'^\|\s*');
  static final _closingPipe = RegExp(r'\s*\|$');

  @override
  bool get canEndBlock => false;

  @override
  bool canParse(BlockParser parser) {
    // Note: matches *next* line, not the current one. We're looking for the
    // bar separating the head row from the body rows.
    return parser.matchesNext(_tablePattern);
  }

  /// Parses a table into its three parts:
  ///
  /// * a head row of head cells (`<th>` cells)
  /// * a divider of hyphens and pipes (not rendered)
  /// * many body rows of body cells (`<td>` cells)
  @override
  Node? parse(BlockParser parser) {
    final alignments = parseAlignments(parser.next!);
    final columnCount = alignments.length;
    final headRow = parseRow(parser, alignments, 'th');
    if (headRow.children!.length != columnCount) {
      return null;
    }
    final head = Element('thead', [headRow]);

    // Advance past the divider of hyphens.
    parser.advance();

    final rows = <Element>[];
    while (!parser.isDone && !BlockSyntax.isAtBlockEnd(parser)) {
      final row = parseRow(parser, alignments, 'td');
      while (row.children!.length < columnCount) {
        // Insert synthetic empty cells.
        row.children!.add(Element.empty('td'));
      }
      while (row.children!.length > columnCount) {
        row.children!.removeLast();
      }
      rows.add(row);
    }
    if (rows.isEmpty) {
      return Element('table', [head]);
    } else {
      final body = Element('tbody', rows);

      return Element('table', [head, body]);
    }
  }

  List<String?> parseAlignments(String line) {
    line = line.replaceFirst(_openingPipe, '').replaceFirst(_closingPipe, '');
    return line.split('|').map((column) {
      column = column.trim();
      if (column.startsWith(':') && column.endsWith(':')) {
        return 'center';
      }
      if (column.startsWith(':')) {
        return 'left';
      }
      if (column.endsWith(':')) {
        return 'right';
      }
      return null;
    }).toList();
  }

  Element parseRow(
      BlockParser parser, List<String?> alignments, String cellType) {
    final line = parser.current
        .replaceFirst(_openingPipe, '')
        .replaceFirst(_closingPipe, '');
    final cells = line.split(_pipePattern);
    parser.advance();
    final row = <Element>[];
    String? preCell;

    for (var cell in cells) {
      if (preCell != null) {
        cell = preCell + cell;
        preCell = null;
      }
      if (cell.endsWith('\\')) {
        preCell = '${cell.substring(0, cell.length - 1)}|';
        continue;
      }

      final contents = UnparsedContent(cell);
      row.add(Element(cellType, [contents]));
    }

    for (var i = 0; i < row.length && i < alignments.length; i++) {
      if (alignments[i] == null) {
        continue;
      }
      row[i].attributes['style'] = 'text-align: ${alignments[i]};';
    }

    return Element('tr', row);
  }
}

/// Parses paragraphs of regular text.
class ParagraphSyntax extends BlockSyntax {
  const ParagraphSyntax();

  static final _reflinkDefinitionStart = RegExp(r'[ ]{0,3}\[');

  static final _whitespacePattern = RegExp(r'^\s*$');

  @override
  bool get canEndBlock => false;

  @override
  bool canParse(BlockParser parser) => true;

  @override
  Node parse(BlockParser parser) {
    final childLines = <String>[];

    // Eat until we hit something that ends a paragraph.
    while (!BlockSyntax.isAtBlockEnd(parser)) {
      childLines.add(parser.current);
      parser.advance();
    }

    final paragraphLines = _extractReflinkDefinitions(parser, childLines);
    if (paragraphLines == null) {
      // Paragraph consisted solely of reference link definitions.
      return Text('');
    } else {
      final contents = UnparsedContent(paragraphLines.join('\n'));
      return Element('p', [contents]);
    }
  }

  /// Extract reference link definitions from the front of the paragraph, and
  /// return the remaining paragraph lines.
  List<String>? _extractReflinkDefinitions(
      BlockParser parser, List<String> lines) {
    bool lineStartsReflinkDefinition(int i) =>
        lines[i].startsWith(_reflinkDefinitionStart);

    var i = 0;
    loopOverDefinitions:
    while (true) {
      // Check for reflink definitions.
      if (!lineStartsReflinkDefinition(i)) {
        // It's paragraph content from here on out.
        break;
      }
      var contents = lines[i];
      var j = i + 1;
      while (j < lines.length) {
        // Check to see if the _next_ line might start a reflink definition.
        // Even if it turns out not to be, but it started with a '[', then it
        // is not a part of _this_ possible reflink definition.
        if (lineStartsReflinkDefinition(j)) {
          // Try to parse [contents] as a reflink definition.
          if (_parseReflinkDefinition(parser, contents)) {
            // Loop again, starting at the next possible reflink definition.
            i = j;
            continue loopOverDefinitions;
          } else {
            // Could not parse [contents] as a reflink definition.
            break;
          }
        } else {
          contents = '$contents\n${lines[j]}';
          j++;
        }
      }
      // End of the block.
      if (_parseReflinkDefinition(parser, contents)) {
        i = j;
        break;
      }

      // It may be that there is a reflink definition starting at [i], but it
      // does not extend all the way to [j], such as:
      //
      //     [link]: url     // line i
      //     "title"
      //     garbage
      //     [link2]: url   // line j
      //
      // In this case, [i, i+1] is a reflink definition, and the rest is
      // paragraph content.
      while (j >= i) {
        // This isn't the most efficient loop, what with this big ole'
        // Iterable allocation (`getRange`) followed by a big 'ole String
        // allocation, but we
        // must walk backwards, checking each range.
        contents = lines.getRange(i, j).join('\n');
        if (_parseReflinkDefinition(parser, contents)) {
          // That is the last reflink definition. The rest is paragraph
          // content.
          i = j;
          break;
        }
        j--;
      }
      // The ending was not a reflink definition at all. Just paragraph
      // content.

      break;
    }

    if (i == lines.length) {
      // No paragraph content.
      return null;
    } else {
      // Ends with paragraph content.
      return lines.sublist(i);
    }
  }

  // Parse [contents] as a reference link definition.
  //
  // Also adds the reference link definition to the document.
  //
  // Returns whether [contents] could be parsed as a reference link definition.
  bool _parseReflinkDefinition(BlockParser parser, String contents) {
    final pattern = RegExp(
        // Leading indentation.
        r'''^[ ]{0,3}'''
        // Reference id in brackets, and URL.
        r'''\[((?:\\\]|[^\]])+)\]:\s*(?:<(\S+)>|(\S+))\s*'''
        // Title in double or single quotes, or parens.
        r'''("[^"]+"|'[^']+'|\([^)]+\)|)\s*$''',
        multiLine: true);
    final match = pattern.firstMatch(contents);
    if (match == null) {
      // Not a reference link definition.
      return false;
    }
    if (match[0]!.length < contents.length) {
      // Trailing text. No good.
      return false;
    }

    var label = match[1]!;
    final destination = match[2] ?? match[3];
    var title = match[4];

    // The label must contain at least one non-whitespace character.
    if (_whitespacePattern.hasMatch(label)) {
      return false;
    }

    if (title == '') {
      // No title.
      title = null;
    } else {
      // Remove "", '', or ().
      title = title!.substring(1, title.length - 1);
    }

    // References are case-insensitive, and internal whitespace is compressed.
    label =
        label.toLowerCase().trim().replaceAll(_oneOrMoreWhitespacePattern, ' ');

    parser.document.linkReferences
        .putIfAbsent(label, () => LinkReference(label, destination!, title!));
    return true;
  }
}
