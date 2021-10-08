import 'dart:math' as math;

import '../../quill_delta.dart';
import '../style.dart';
import 'embed.dart';
import 'line.dart';
import 'node.dart';

/// A leaf in Quill document tree.
abstract class Leaf extends Node {
  /// Creates a new [Leaf] with specified [data].
  factory Leaf(Object data) {
    if (data is Embeddable) {
      return Embed(data);
    }
    final text = data as String;
    assert(text.isNotEmpty);
    return Text(text);
  }

  Leaf.val(Object val) : _value = val;

  /// Contents of this node, either a String if this is a [Text] or an
  /// [Embed] if this is an [BlockEmbed].
  Object get value => _value;
  Object _value;

  @override
  void applyStyle(Style value) {
    assert(value.isInline || value.isIgnored || value.isEmpty,
        'Unable to apply Style to leaf: $value');
    super.applyStyle(value);
  }

  @override
  Line? get parent => super.parent as Line?;

  @override
  int get length {
    if (_value is String) {
      return (_value as String).length;
    }
    // return 1 for embedded object
    return 1;
  }

  @override
  Delta toDelta() {
    final data =
        _value is Embeddable ? (_value as Embeddable).toJson() : _value;
    return Delta()..insert(data, style.toJson());
  }

  @override
  void insert(int index, Object data, Style? style) {
    assert(index >= 0 && index <= length);
    final node = Leaf(data);
    if (index < length) {
      splitAt(index)!.insertBefore(node);
    } else {
      insertAfter(node);
    }
    node.format(style);
  }

  @override
  void retain(int index, int? len, Style? style) {
    if (style == null) {
      return;
    }

    final local = math.min(length - index, len!);
    final remain = len - local;
    final node = _isolate(index, local);

    if (remain > 0) {
      assert(node.next != null);
      node.next!.retain(0, remain, style);
    }
    node.format(style);
  }

  @override
  void delete(int index, int? len) {
    assert(index < length);

    final local = math.min(length - index, len!);
    final target = _isolate(index, local);
    final prev = target.previous as Leaf?;
    final next = target.next as Leaf?;
    target.unlink();

    final remain = len - local;
    if (remain > 0) {
      assert(next != null);
      next!.delete(0, remain);
    }

    if (prev != null) {
      prev.adjust();
    }
  }

  /// Adjust this text node by merging it with adjacent nodes if they share
  /// the same style.
  @override
  void adjust() {
    if (this is Embed) {
      // Embed nodes cannot be merged with text nor other embeds (in fact,
      // there could be no two adjacent embeds on the same line since an
      // embed occupies an entire line).
      return;
    }

    // This is a text node and it can only be merged with other text nodes.
    var node = this as Text;

    // Merging it with previous node if style is the same.
    final prev = node.previous;
    if (!node.isFirst && prev is Text && prev.style == node.style) {
      prev._value = prev.value + node.value;
      node.unlink();
      node = prev;
    }

    // Merging it with next node if style is the same.
    final next = node.next;
    if (!node.isLast && next is Text && next.style == node.style) {
      node._value = node.value + next.value;
      next.unlink();
    }
  }

  /// Splits this leaf node at [index] and returns new node.
  ///
  /// If this is the last node in its list and [index] equals this node's
  /// length then this method returns `null` as there is nothing left to split.
  /// If there is another leaf node after this one and [index] equals this
  /// node's length then the next leaf node is returned.
  ///
  /// If [index] equals to `0` then this node itself is returned unchanged.
  ///
  /// In case a new node is actually split from this one, it inherits this
  /// node's style.
  Leaf? splitAt(int index) {
    assert(index >= 0 && index <= length);
    if (index == 0) {
      return this;
    }
    if (index == length) {
      return isLast ? null : next as Leaf?;
    }

    assert(this is Text);
    final text = _value as String;
    _value = text.substring(0, index);
    final split = Leaf(text.substring(index))..applyStyle(style);
    insertAfter(split);
    return split;
  }

  /// Cuts a leaf from [index] to the end of this node and returns new node
  /// in detached state (e.g. [mounted] returns `false`).
  ///
  /// Splitting logic is identical to one described in [splitAt], meaning this
  /// method may return `null`.
  Leaf? cutAt(int index) {
    assert(index >= 0 && index <= length);
    final cut = splitAt(index);
    cut?.unlink();
    return cut;
  }

  /// Formats this node and optimizes it with adjacent leaf nodes if needed.
  void format(Style? style) {
    if (style != null && style.isNotEmpty) {
      applyStyle(style);
    }
    adjust();
  }

  /// Isolates a new leaf starting at [index] with specified [length].
  ///
  /// Splitting logic is identical to one described in [splitAt], with one
  /// exception that it is required for [index] to always be less than this
  /// node's length. As a result this method always returns a [LeafNode]
  /// instance. Returned node may still be the same as this node
  /// if provided [index] is `0`.
  Leaf _isolate(int index, int length) {
    assert(
        index >= 0 && index < this.length && (index + length <= this.length));
    final target = splitAt(index)!..splitAt(length);
    return target;
  }
}

/// A span of formatted text within a line in a Quill document.
///
/// Text is a leaf node of a document tree.
///
/// Parent of a text node is always a [Line], and as a consequence text
/// node's [value] cannot contain any line-break characters.
///
/// See also:
///
///   * [Embed], a leaf node representing an embeddable object.
///   * [Line], a node representing a line of text.
class Text extends Leaf {
  Text([String text = ''])
      : assert(!text.contains('\n')),
        super.val(text);

  @override
  Node newInstance() => Text(value);

  @override
  String get value => _value as String;

  @override
  String toPlainText() => value;
}

/// An embed node inside of a line in a Quill document.
///
/// Embed node is a leaf node similar to [Text]. It represents an arbitrary
/// piece of non-textual content embedded into a document, such as, image,
/// horizontal rule, video, or any other object with defined structure,
/// like a tweet, for instance.
///
/// Embed node's length is always `1` character and it is represented with
/// unicode object replacement character in the document text.
///
/// Any inline style can be applied to an embed, however this does not
/// necessarily mean the embed will look according to that style. For instance,
/// applying "bold" style to an image gives no effect, while adding a "link" to
/// an image actually makes the image react to user's action.
class Embed extends Leaf {
  Embed(Embeddable data) : super.val(data);

  static const kObjectReplacementCharacter = '\uFFFC';

  @override
  Node newInstance() => throw UnimplementedError();

  @override
  Embeddable get value => super.value as Embeddable;

  /// // Embed nodes are represented as unicode object replacement character in
  // plain text.
  @override
  String toPlainText() => kObjectReplacementCharacter;
}
