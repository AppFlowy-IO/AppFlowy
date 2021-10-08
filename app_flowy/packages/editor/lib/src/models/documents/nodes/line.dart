import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../../quill_delta.dart';
import '../attribute.dart';
import '../style.dart';
import 'block.dart';
import 'container.dart';
import 'embed.dart';
import 'leaf.dart';
import 'node.dart';

/// A line of rich text in a Quill document.
///
/// Line serves as a container for [Leaf]s, like [Text] and [Embed].
///
/// When a line contains an embed, it fully occupies the line, no other embeds
/// or text nodes are allowed.
class Line extends Container<Leaf?> {
  @override
  Leaf get defaultChild => Text();

  @override
  int get length => super.length + 1;

  /// Returns `true` if this line contains an embedded object.
  bool get hasEmbed {
    return children.any((child) => child is Embed);
  }

  /// Returns next [Line] or `null` if this is the last line in the document.
  Line? get nextLine {
    if (!isLast) {
      return next is Block ? (next as Block).first as Line? : next as Line?;
    }
    if (parent is! Block) {
      return null;
    }

    if (parent!.isLast) {
      return null;
    }
    return parent!.next is Block
        ? (parent!.next as Block).first as Line?
        : parent!.next as Line?;
  }

  @override
  Node newInstance() => Line();

  @override
  Delta toDelta() {
    final delta = children
        .map((child) => child.toDelta())
        .fold(Delta(), (dynamic a, b) => a.concat(b));
    var attributes = style;
    if (parent is Block) {
      final block = parent as Block;
      attributes = attributes.mergeAll(block.style);
    }
    delta.insert('\n', attributes.toJson());
    return delta;
  }

  @override
  String toPlainText() => '${super.toPlainText()}\n';

  @override
  String toString() {
    final body = children.join(' → ');
    final styleString = style.isNotEmpty ? ' $style' : '';
    return '¶ $body ⏎$styleString';
  }

  @override
  void insert(int index, Object data, Style? style) {
    if (data is Embeddable) {
      // We do not check whether this line already has any children here as
      // inserting an embed into a line with other text is acceptable from the
      // Delta format perspective.
      // We rely on heuristic rules to ensure that embeds occupy an entire line.
      _insertSafe(index, data, style);
      return;
    }

    final text = data as String;
    final lineBreak = text.indexOf('\n');
    if (lineBreak < 0) {
      _insertSafe(index, text, style);
      // No need to update line or block format since those attributes can only
      // be attached to `\n` character and we already know it's not present.
      return;
    }

    final prefix = text.substring(0, lineBreak);
    _insertSafe(index, prefix, style);
    if (prefix.isNotEmpty) {
      index += prefix.length;
    }

    // Next line inherits our format.
    final nextLine = _getNextLine(index);

    // Reset our format and unwrap from a block if needed.
    clearStyle();
    if (parent is Block) {
      _unwrap();
    }

    // Now we can apply new format and re-layout.
    _format(style);

    // Continue with remaining part.
    final remain = text.substring(lineBreak + 1);
    nextLine.insert(0, remain, style);
  }

  @override
  void retain(int index, int? len, Style? style) {
    if (style == null) {
      return;
    }
    final thisLength = length;

    final local = math.min(thisLength - index, len!);
    // If index is at newline character then this is a line/block style update.
    final isLineFormat = (index + local == thisLength) && local == 1;

    if (isLineFormat) {
      assert(style.values.every((attr) => attr.scope == AttributeScope.BLOCK),
          'It is not allowed to apply inline attributes to line itself.');
      _format(style);
    } else {
      // Otherwise forward to children as it's an inline format update.
      assert(style.values.every((attr) => attr.scope == AttributeScope.INLINE));
      assert(index + local != thisLength);
      super.retain(index, local, style);
    }

    final remain = len - local;
    if (remain > 0) {
      assert(nextLine != null);
      nextLine!.retain(0, remain, style);
    }
  }

  @override
  void delete(int index, int? len) {
    final local = math.min(length - index, len!);
    final isLFDeleted = index + local == length; // Line feed
    if (isLFDeleted) {
      // Our newline character deleted with all style information.
      clearStyle();
      if (local > 1) {
        // Exclude newline character from delete range for children.
        super.delete(index, local - 1);
      }
    } else {
      super.delete(index, local);
    }

    final remaining = len - local;
    if (remaining > 0) {
      assert(nextLine != null);
      nextLine!.delete(0, remaining);
    }

    if (isLFDeleted && isNotEmpty) {
      // Since we lost our line-break and still have child text nodes those must
      // migrate to the next line.

      // nextLine might have been unmounted since last assert so we need to
      // check again we still have a line after us.
      assert(nextLine != null);

      // Move remaining children in this line to the next line so that all
      // attributes of nextLine are preserved.
      nextLine!.moveChildToNewParent(this);
      moveChildToNewParent(nextLine);
    }

    if (isLFDeleted) {
      // Now we can remove this line.
      final block = parent!; // remember reference before un-linking.
      unlink();
      block.adjust();
    }
  }

  /// Formats this line.
  void _format(Style? newStyle) {
    if (newStyle == null || newStyle.isEmpty) {
      return;
    }

    applyStyle(newStyle);
    final blockStyle = newStyle.getBlockExceptHeader();
    if (blockStyle == null) {
      return;
    } // No block-level changes

    if (parent is Block) {
      final parentStyle = (parent as Block).style.getBlocksExceptHeader();
      // Ensure that we're only unwrapping the block only if we unset a single
      // block format in the `parentStyle` and there are no more block formats
      // left to unset.
      if (blockStyle.value == null &&
          parentStyle.containsKey(blockStyle.key) &&
          parentStyle.length == 1) {
        _unwrap();
      } else if (!const MapEquality()
          .equals(newStyle.getBlocksExceptHeader(), parentStyle)) {
        _unwrap();
        // Block style now can contain multiple attributes
        if (newStyle.attributes.keys
            .any(Attribute.exclusiveBlockKeys.contains)) {
          parentStyle.removeWhere(
              (key, attr) => Attribute.exclusiveBlockKeys.contains(key));
        }
        parentStyle.removeWhere(
            (key, attr) => newStyle?.attributes.keys.contains(key) ?? false);
        final parentStyleToMerge = Style.attr(parentStyle);
        newStyle = newStyle.mergeAll(parentStyleToMerge);
        _applyBlockStyles(newStyle);
      } // else the same style, no-op.
    } else if (blockStyle.value != null) {
      // Only wrap with a new block if this is not an unset
      _applyBlockStyles(newStyle);
    }
  }

  void _applyBlockStyles(Style newStyle) {
    var block = Block();
    for (final style in newStyle.getBlocksExceptHeader().values) {
      block = block..applyAttribute(style);
    }
    _wrap(block);
    block.adjust();
  }

  /// Wraps this line with new parent [block].
  ///
  /// This line can not be in a [Block] when this method is called.
  void _wrap(Block block) {
    assert(parent != null && parent is! Block);
    insertAfter(block);
    unlink();
    block.add(this);
  }

  /// Unwraps this line from it's parent [Block].
  ///
  /// This method asserts if current [parent] of this line is not a [Block].
  void _unwrap() {
    if (parent is! Block) {
      throw ArgumentError('Invalid parent');
    }
    final block = parent as Block;

    assert(block.children.contains(this));

    if (isFirst) {
      unlink();
      block.insertBefore(this);
    } else if (isLast) {
      unlink();
      block.insertAfter(this);
    } else {
      final before = block.clone() as Block;
      block.insertBefore(before);

      var child = block.first as Line;
      while (child != this) {
        child.unlink();
        before.add(child);
        child = block.first as Line;
      }
      unlink();
      block.insertBefore(this);
    }
    block.adjust();
  }

  Line _getNextLine(int index) {
    assert(index == 0 || (index > 0 && index < length));

    final line = clone() as Line;
    insertAfter(line);
    if (index == length - 1) {
      return line;
    }

    final query = queryChild(index, false);
    while (!query.node!.isLast) {
      final next = (last as Leaf)..unlink();
      line.addFirst(next);
    }
    final child = query.node as Leaf;
    final cut = child.splitAt(query.offset);
    cut?.unlink();
    line.addFirst(cut);
    return line;
  }

  void _insertSafe(int index, Object data, Style? style) {
    assert(index == 0 || (index > 0 && index < length));

    if (data is String) {
      assert(!data.contains('\n'));
      if (data.isEmpty) {
        return;
      }
    }

    if (isEmpty) {
      final child = Leaf(data);
      add(child);
      child.format(style);
    } else {
      final result = queryChild(index, true);
      result.node!.insert(result.offset, data, style);
    }
  }

  /// Returns style for specified text range.
  ///
  /// Only attributes applied to all characters within this range are
  /// included in the result. Inline and line level attributes are
  /// handled separately, e.g.:
  ///
  /// - line attribute X is included in the result only if it exists for
  ///   every line within this range (partially included lines are counted).
  /// - inline attribute X is included in the result only if it exists
  ///   for every character within this range (line-break characters excluded).
  Style collectStyle(int offset, int len) {
    final local = math.min(length - offset, len);
    var result = Style();
    final excluded = <Attribute>{};

    void _handle(Style style) {
      if (result.isEmpty) {
        excluded.addAll(style.values);
      } else {
        for (final attr in result.values) {
          if (!style.containsKey(attr.key)) {
            excluded.add(attr);
          }
        }
      }
      final remaining = style.removeAll(excluded);
      result = result.removeAll(excluded);
      result = result.mergeAll(remaining);
    }

    final data = queryChild(offset, true);
    var node = data.node as Leaf?;
    if (node != null) {
      result = result.mergeAll(node.style);
      var pos = node.length - data.offset;
      while (!node!.isLast && pos < local) {
        node = node.next as Leaf?;
        _handle(node!.style);
        pos += node.length;
      }
    }

    result = result.mergeAll(style);
    if (parent is Block) {
      final block = parent as Block;
      result = result.mergeAll(block.style);
    }

    final remaining = len - local;
    if (remaining > 0) {
      final rest = nextLine!.collectStyle(0, remaining);
      _handle(rest);
    }

    return result;
  }

  /// Returns all styles for any character within the specified text range.
  List<Style> collectAllStyles(int offset, int len) {
    final local = math.min(length - offset, len);
    final result = <Style>[];

    final data = queryChild(offset, true);
    var node = data.node as Leaf?;
    if (node != null) {
      result.add(node.style);
      var pos = node.length - data.offset;
      while (!node!.isLast && pos < local) {
        node = node.next as Leaf?;
        result.add(node!.style);
        pos += node.length;
      }
    }

    result.add(style);
    if (parent is Block) {
      final block = parent as Block;
      result.add(block.style);
    }

    final remaining = len - local;
    if (remaining > 0) {
      final rest = nextLine!.collectAllStyles(0, remaining);
      result.addAll(rest);
    }

    return result;
  }
}
