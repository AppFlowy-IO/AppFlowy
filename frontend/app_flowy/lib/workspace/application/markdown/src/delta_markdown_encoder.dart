import 'dart:convert';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter_quill/src/models/documents/attribute.dart';
import 'package:flutter_quill/src/models/documents/nodes/embeddable.dart';
import 'package:flutter_quill/src/models/documents/style.dart';
import 'package:flutter_quill/src/models/quill_delta.dart';

class DeltaMarkdownEncoder extends Converter<String, String> {
  static const _lineFeedAsciiCode = 0x0A;

  late StringBuffer markdownBuffer;
  late StringBuffer lineBuffer;

  Attribute? currentBlockStyle;
  late Style currentInlineStyle;

  late List<String> currentBlockLines;

  /// Converts the [input] delta to Markdown.
  @override
  String convert(String input) {
    markdownBuffer = StringBuffer();
    lineBuffer = StringBuffer();
    currentInlineStyle = Style();
    currentBlockLines = <String>[];

    final inputJson = jsonDecode(input) as List<dynamic>?;
    if (inputJson is! List<dynamic>) {
      throw ArgumentError('Unexpected formatting of the input delta string.');
    }
    final delta = Delta.fromJson(inputJson);
    final iterator = DeltaIterator(delta);

    while (iterator.hasNext) {
      final operation = iterator.next();

      if (operation.data is String) {
        final operationData = operation.data as String;

        if (!operationData.contains('\n')) {
          _handleInline(lineBuffer, operationData, operation.attributes);
        } else {
          _handleLine(operationData, operation.attributes);
        }
      } else if (operation.data is Map<String, dynamic>) {
        _handleEmbed(operation.data as Map<String, dynamic>);
      } else {
        throw ArgumentError('Unexpected formatting of the input delta string.');
      }
    }

    _handleBlock(currentBlockStyle); // Close the last block

    return markdownBuffer.toString();
  }

  void _handleInline(
    StringBuffer buffer,
    String text,
    Map<String, dynamic>? attributes,
  ) {
    final style = Style.fromJson(attributes);

    // First close any current styles if needed
    final markedForRemoval = <Attribute>[];
    // Close the styles in reverse order, e.g. **_ for _**Test**_.
    for (final value in currentInlineStyle.attributes.values.toList().reversed) {
      // TODO(tillf): Is block correct?
      if (value.scope == AttributeScope.BLOCK) {
        continue;
      }
      if (style.containsKey(value.key)) {
        continue;
      }

      final padding = _trimRight(buffer);
      _writeAttribute(buffer, value, close: true);
      if (padding.isNotEmpty) {
        buffer.write(padding);
      }
      markedForRemoval.add(value);
    }

    // Make sure to remove all attributes that are marked for removal.
    for (final value in markedForRemoval) {
      currentInlineStyle.attributes.removeWhere((_, v) => v == value);
    }

    // Now open any new styles.
    for (final attribute in style.attributes.values) {
      // TODO(tillf): Is block correct?
      if (attribute.scope == AttributeScope.BLOCK) {
        continue;
      }
      if (currentInlineStyle.containsKey(attribute.key)) {
        continue;
      }
      final originalText = text;
      text = text.trimLeft();
      final padding = ' ' * (originalText.length - text.length);
      if (padding.isNotEmpty) {
        buffer.write(padding);
      }
      _writeAttribute(buffer, attribute);
    }

    // Write the text itself
    buffer.write(text);
    currentInlineStyle = style;
  }

  void _handleLine(String data, Map<String, dynamic>? attributes) {
    final span = StringBuffer();

    for (var i = 0; i < data.length; i++) {
      if (data.codeUnitAt(i) == _lineFeedAsciiCode) {
        if (span.isNotEmpty) {
          // Write the span if it's not empty.
          _handleInline(lineBuffer, span.toString(), attributes);
        }
        // Close any open inline styles.
        _handleInline(lineBuffer, '', null);

        final lineBlock =
            Style.fromJson(attributes).attributes.values.singleWhereOrNull((a) => a.scope == AttributeScope.BLOCK);

        if (lineBlock == currentBlockStyle) {
          currentBlockLines.add(lineBuffer.toString());
        } else {
          _handleBlock(currentBlockStyle);
          currentBlockLines
            ..clear()
            ..add(lineBuffer.toString());

          currentBlockStyle = lineBlock;
        }
        lineBuffer.clear();

        span.clear();
      } else {
        span.writeCharCode(data.codeUnitAt(i));
      }
    }

    // Remaining span
    if (span.isNotEmpty) {
      _handleInline(lineBuffer, span.toString(), attributes);
    }
  }

  void _handleEmbed(Map<String, dynamic> data) {
    final embed = BlockEmbed(data.keys.first, data.values.first as String);

    if (embed.type == 'image') {
      _writeEmbedTag(lineBuffer, embed);
      _writeEmbedTag(lineBuffer, embed, close: true);
    } else if (embed.type == 'divider') {
      _writeEmbedTag(lineBuffer, embed);
      _writeEmbedTag(lineBuffer, embed, close: true);
    }
  }

  void _handleBlock(Attribute? blockStyle) {
    if (currentBlockLines.isEmpty) {
      return; // Empty block
    }

    // If there was a block before this one, add empty line between the blocks
    if (markdownBuffer.isNotEmpty) {
      markdownBuffer.writeln();
    }

    if (blockStyle == null) {
      markdownBuffer
        ..write(currentBlockLines.join('\n'))
        ..writeln();
    } else if (blockStyle == Attribute.codeBlock) {
      _writeAttribute(markdownBuffer, blockStyle);
      markdownBuffer.write(currentBlockLines.join('\n'));
      _writeAttribute(markdownBuffer, blockStyle, close: true);
      markdownBuffer.writeln();
    } else {
      // Dealing with lists or a quote.
      for (final line in currentBlockLines) {
        _writeBlockTag(markdownBuffer, blockStyle);
        markdownBuffer
          ..write(line)
          ..writeln();
      }
    }
  }

  String _trimRight(StringBuffer buffer) {
    final text = buffer.toString();
    if (!text.endsWith(' ')) {
      return '';
    }

    final result = text.trimRight();
    buffer
      ..clear()
      ..write(result);
    return ' ' * (text.length - result.length);
  }

  void _writeAttribute(
    StringBuffer buffer,
    Attribute attribute, {
    bool close = false,
  }) {
    if (attribute.key == Attribute.bold.key) {
      buffer.write('**');
    } else if (attribute.key == Attribute.italic.key) {
      buffer.write('_');
    } else if (attribute.key == Attribute.link.key) {
      buffer.write(!close ? '[' : '](${attribute.value})');
    } else if (attribute == Attribute.codeBlock) {
      buffer.write(!close ? '```\n' : '\n```');
    } else if (attribute.key == Attribute.background.key) {
      buffer.write(!close ? '<mark>' : '</mark>');
    } else if (attribute.key == Attribute.underline.key) {
      buffer.write(!close ? '<u>' : '</u>');
    } else if (attribute.key == Attribute.codeBlock.key) {
      buffer.write(!close ? '```\n' : '\n```');
    } else if (attribute.key == Attribute.inlineCode.key) {
      buffer.write(!close ? '`' : '`');
    } else if (attribute.key == Attribute.strikeThrough.key) {
      buffer.write(!close ? '~~' : '~~');
    } else {
      throw ArgumentError('Cannot handle $attribute');
    }
  }

  void _writeBlockTag(
    StringBuffer buffer,
    Attribute block, {
    bool close = false,
  }) {
    if (close) {
      return; // no close tag needed for simple blocks.
    }

    if (block == Attribute.blockQuote) {
      buffer.write('> ');
    } else if (block == Attribute.ul) {
      buffer.write('* ');
    } else if (block == Attribute.ol) {
      buffer.write('1. ');
    } else if (block.key == Attribute.h1.key && block.value == 1) {
      buffer.write('# ');
    } else if (block.key == Attribute.h2.key && block.value == 2) {
      buffer.write('## ');
    } else if (block.key == Attribute.h3.key && block.value == 3) {
      buffer.write('### ');
    } else if (block.key == Attribute.list.key) {
      buffer.write('* ');
    } else {
      throw ArgumentError('Cannot handle block $block');
    }
  }

  void _writeEmbedTag(
    StringBuffer buffer,
    BlockEmbed embed, {
    bool close = false,
  }) {
    const kImageType = 'image';
    const kDividerType = 'divider';

    if (embed.type == kImageType) {
      if (close) {
        buffer.write('](${embed.data})');
      } else {
        buffer.write('![');
      }
    } else if (embed.type == kDividerType && close) {
      buffer.write('\n---\n\n');
    }
  }
}
