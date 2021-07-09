import 'dart:collection';

import '../../quill_delta.dart';
import '../attribute.dart';
import '../style.dart';
import 'container.dart';
import 'line.dart';

/// An abstract node in a document tree.
///
/// Represents a segment of a Quill document with specified [offset]
/// and [length].
///
/// The [offset] property is relative to [parent]. See also [documentOffset]
/// which provides absolute offset of this node within the document.
///
/// The current parent node is exposed by the [parent] property.
abstract class Node extends LinkedListEntry<Node> {
  /// Current parent of this node. May be null if this node is not mounted.
  Container? parent;

  Style get style => _style;
  Style _style = Style();

  /// Returns `true` if this node is the first node in the [parent] list.
  bool get isFirst => list!.first == this;

  /// Returns `true` if this node is the last node in the [parent] list.
  bool get isLast => list!.last == this;

  /// Length of this node in characters.
  int get length;

  Node clone() => newInstance()..applyStyle(style);

  /// Offset in characters of this node relative to [parent] node.
  ///
  /// To get offset of this node in the document see [documentOffset].
  int get offset {
    var offset = 0;
    if (list == null || isFirst) {
      return offset;
    }
    var curr = this;
    do {
      curr = curr.previous!;
      offset += curr.length;
    } while (!curr.isFirst);
    return offset;
  }

  /// Offset in characters of this node in the document.
  int get documentOffset {
    final parentOffset = (parent is! Root) ? parent!.documentOffset : 0;
    return parentOffset + offset;
  }

  /// Returns `true` if this node contains character at specified [offset] in
  /// the document.
  bool containsOffset(int offset) {
    final docOffset = documentOffset;
    return docOffset <= offset && offset < docOffset + length;
  }

  void applyAttribute(Attribute attribute) {
    _style = _style.merge(attribute);
  }

  void applyStyle(Style otherStyle) {
    _style = _style.mergeAll(otherStyle);
  }

  void clearStyle() {
    _style = Style();
  }

  @override
  void insertBefore(Node entry) {
    assert(entry.parent == null && parent != null);
    entry.parent = parent;
    super.insertBefore(entry);
  }

  @override
  void insertAfter(Node entry) {
    assert(entry.parent == null && parent != null);
    entry.parent = parent;
    super.insertAfter(entry);
  }

  @override
  void unlink() {
    assert(parent != null);
    parent = null;
    super.unlink();
  }

  void adjust() {/* no-op */}

  // Subclass overridden method

  Node newInstance();

  String toPlainText();

  Delta toDelta();

  void insert(int index, Object data, Style? style);

  void retain(int index, int? length, Style? style);

  void delete(int index, int? length);
}

/// Root node of document tree.
class Root extends Container<Container<Node?>> {
  @override
  Node newInstance() => Root();

  @override
  Container<Node?> get defaultChild => Line();

  @override
  Delta toDelta() => children
      .map((child) => child.toDelta())
      .fold(Delta(), (a, b) => a.concat(b));
}
