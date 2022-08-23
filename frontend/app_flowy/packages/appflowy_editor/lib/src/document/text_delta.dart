import 'dart:collection';
import 'dart:math';

import 'package:appflowy_editor/src/document/attributes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './attributes.dart';

// constant number: 2^53 - 1
const int _maxInt = 9007199254740991;

abstract class TextOperation {
  bool get isEmpty => length == 0;

  int get length;

  Attributes? get attributes => null;

  Map<String, dynamic> toJson();
}

class TextInsert extends TextOperation {
  String content;
  final Attributes? _attributes;

  TextInsert(this.content, [Attributes? attrs]) : _attributes = attrs;

  @override
  int get length {
    return content.length;
  }

  @override
  Attributes? get attributes {
    return _attributes;
  }

  @override
  bool operator ==(Object other) {
    if (other is! TextInsert) {
      return false;
    }
    return content == other.content &&
        mapEquals(_attributes, other._attributes);
  }

  @override
  int get hashCode {
    final contentHash = content.hashCode;
    final attrs = _attributes;
    return Object.hash(
        contentHash, attrs == null ? null : hashAttributes(attrs));
  }

  @override
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'insert': content,
    };
    final attrs = _attributes;
    if (attrs != null) {
      result['attributes'] = {...attrs};
    }
    return result;
  }
}

class TextRetain extends TextOperation {
  int _length;
  final Attributes? _attributes;

  TextRetain(length, [Attributes? attributes])
      : _length = length,
        _attributes = attributes;

  @override
  bool get isEmpty {
    return length == 0;
  }

  @override
  int get length {
    return _length;
  }

  set length(int v) {
    _length = v;
  }

  @override
  Attributes? get attributes {
    return _attributes;
  }

  @override
  bool operator ==(Object other) {
    if (other is! TextRetain) {
      return false;
    }
    return _length == other.length && mapEquals(_attributes, other._attributes);
  }

  @override
  int get hashCode {
    final attrs = _attributes;
    return Object.hash(_length, attrs == null ? null : hashAttributes(attrs));
  }

  @override
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'retain': _length,
    };
    final attrs = _attributes;
    if (attrs != null) {
      result['attributes'] = {...attrs};
    }
    return result;
  }
}

class TextDelete extends TextOperation {
  int _length;

  TextDelete(int length) : _length = length;

  @override
  int get length {
    return _length;
  }

  set length(int v) {
    _length = v;
  }

  @override
  bool operator ==(Object other) {
    if (other is! TextDelete) {
      return false;
    }
    return _length == other.length;
  }

  @override
  int get hashCode {
    return _length.hashCode;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'delete': _length,
    };
  }
}

class _OpIterator {
  final UnmodifiableListView<TextOperation> _operations;
  int _index = 0;
  int _offset = 0;

  _OpIterator(List<TextOperation> operations)
      : _operations = UnmodifiableListView(operations);

  bool get hasNext {
    return peekLength() < _maxInt;
  }

  TextOperation? peek() {
    if (_index >= _operations.length) {
      return null;
    }

    return _operations[_index];
  }

  int peekLength() {
    if (_index < _operations.length) {
      final op = _operations[_index];
      return op.length - _offset;
    }
    return _maxInt;
  }

  TextOperation _next([int? length]) {
    length ??= _maxInt;

    if (_index >= _operations.length) {
      return TextRetain(_maxInt);
    }

    final nextOp = _operations[_index];

    final offset = _offset;
    final opLength = nextOp.length;
    if (length >= opLength - offset) {
      length = opLength - offset;
      _index += 1;
      _offset = 0;
    } else {
      _offset += length;
    }
    if (nextOp is TextDelete) {
      return TextDelete(length);
    }

    if (nextOp is TextRetain) {
      return TextRetain(
        length,
        nextOp.attributes,
      );
    }

    if (nextOp is TextInsert) {
      return TextInsert(
        nextOp.content.substring(offset, offset + length),
        nextOp.attributes,
      );
    }

    return TextRetain(_maxInt);
  }

  List<TextOperation> rest() {
    if (!hasNext) {
      return [];
    } else if (_offset == 0) {
      return _operations.sublist(_index);
    } else {
      final offset = _offset;
      final index = _index;
      final next = _next();
      final rest = _operations.sublist(_index);
      _offset = offset;
      _index = index;
      return [next] + rest;
    }
  }
}

TextOperation? _textOperationFromJson(Map<String, dynamic> json) {
  TextOperation? result;

  if (json['insert'] is String) {
    final attrs = json['attributes'] as Map<String, dynamic>?;
    result =
        TextInsert(json['insert'] as String, attrs == null ? null : {...attrs});
  } else if (json['retain'] is int) {
    final attrs = json['attributes'] as Map<String, dynamic>?;
    result =
        TextRetain(json['retain'] as int, attrs == null ? null : {...attrs});
  } else if (json['delete'] is int) {
    result = TextDelete(json['delete'] as int);
  }

  return result;
}

/// Deltas are a simple, yet expressive format that can be used to describe contents and changes.
/// The format is JSON based, and is human readable, yet easily parsible by machines.
/// Deltas can describe any rich text document, includes all text and formatting information, without the ambiguity and complexity of HTML.
///

/// Basically borrowed from: https://github.com/quilljs/delta
class Delta extends Iterable<TextOperation> {
  final List<TextOperation> _operations;
  String? _rawString;
  List<int>? _runeIndexes;

  factory Delta.fromJson(List<dynamic> list) {
    final operations = <TextOperation>[];

    for (final obj in list) {
      final op = _textOperationFromJson(obj as Map<String, dynamic>);
      if (op != null) {
        operations.add(op);
      }
    }

    return Delta(operations);
  }

  Delta([List<TextOperation>? ops]) : _operations = ops ?? <TextOperation>[];

  void addAll(Iterable<TextOperation> textOps) {
    textOps.forEach(add);
  }

  void add(TextOperation textOp) {
    if (textOp.isEmpty) {
      return;
    }
    _rawString = null;

    if (_operations.isNotEmpty) {
      final lastOp = _operations.last;
      if (lastOp is TextDelete && textOp is TextDelete) {
        lastOp.length += textOp.length;
        return;
      }
      if (mapEquals(lastOp.attributes, textOp.attributes)) {
        if (lastOp is TextInsert && textOp is TextInsert) {
          lastOp.content += textOp.content;
          return;
        }
        // if there is an delete before the insert
        // swap the order
        if (lastOp is TextDelete && textOp is TextInsert) {
          _operations.removeLast();
          _operations.add(textOp);
          _operations.add(lastOp);
          return;
        }
        if (lastOp is TextRetain && textOp is TextRetain) {
          lastOp.length += textOp.length;
          return;
        }
      }
    }

    _operations.add(textOp);
  }

  /// The slice() method does not change the original string.
  /// The start and end parameters specifies the part of the string to extract.
  /// The end position is optional.
  Delta slice(int start, [int? end]) {
    final result = Delta();
    final iterator = _OpIterator(_operations);
    int index = 0;

    while ((end == null || index < end) && iterator.hasNext) {
      TextOperation? nextOp;
      if (index < start) {
        nextOp = iterator._next(start - index);
      } else {
        nextOp = iterator._next(end == null ? null : end - index);
        result.add(nextOp);
      }

      index += nextOp.length;
    }

    return result;
  }

  /// Insert operations have an `insert` key defined.
  /// A String value represents inserting text.
  void insert(String content, [Attributes? attributes]) =>
      add(TextInsert(content, attributes));

  /// Retain operations have a Number `retain` key defined representing the number of characters to keep (other libraries might use the name keep or skip).
  /// An optional `attributes` key can be defined with an Object to describe formatting changes to the character range.
  /// A value of `null` in the `attributes` Object represents removal of that key.
  ///
  /// *Note: It is not necessary to retain the last characters of a document as this is implied.*
  void retain(int length, [Attributes? attributes]) =>
      add(TextRetain(length, attributes));

  /// Delete operations have a Number `delete` key defined representing the number of characters to delete.
  void delete(int length) => add(TextDelete(length));

  /// The length of the string fo the [Delta].
  @override
  int get length {
    return _operations.fold(
        0, (previousValue, element) => previousValue + element.length);
  }

  /// Returns a Delta that is equivalent to applying the operations of own Delta, followed by another Delta.
  Delta compose(Delta other) {
    final thisIter = _OpIterator(_operations);
    final otherIter = _OpIterator(other._operations);
    final ops = <TextOperation>[];

    final firstOther = otherIter.peek();
    if (firstOther != null &&
        firstOther is TextRetain &&
        firstOther.attributes == null) {
      int firstLeft = firstOther.length;
      while (
          thisIter.peek() is TextInsert && thisIter.peekLength() <= firstLeft) {
        firstLeft -= thisIter.peekLength();
        final next = thisIter._next();
        ops.add(next);
      }
      if (firstOther.length - firstLeft > 0) {
        otherIter._next(firstOther.length - firstLeft);
      }
    }

    final delta = Delta(ops);
    while (thisIter.hasNext || otherIter.hasNext) {
      if (otherIter.peek() is TextInsert) {
        final next = otherIter._next();
        delta.add(next);
      } else if (thisIter.peek() is TextDelete) {
        final next = thisIter._next();
        delta.add(next);
      } else {
        // otherIs
        final length = min(thisIter.peekLength(), otherIter.peekLength());
        final thisOp = thisIter._next(length);
        final otherOp = otherIter._next(length);
        final attributes = composeAttributes(
            thisOp.attributes, otherOp.attributes, thisOp is TextRetain);
        if (otherOp is TextRetain && otherOp.length > 0) {
          TextOperation? newOp;
          if (thisOp is TextRetain) {
            newOp = TextRetain(length, attributes);
          } else if (thisOp is TextInsert) {
            newOp = TextInsert(thisOp.content, attributes);
          }

          if (newOp != null) {
            delta.add(newOp);
          }

          // Optimization if rest of other is just retain
          if (!otherIter.hasNext &&
              delta._operations.isNotEmpty &&
              delta._operations.last == newOp) {
            final rest = Delta(thisIter.rest());
            return (delta + rest)..chop();
          }
        } else if (otherOp is TextDelete && (thisOp is TextRetain)) {
          delta.add(otherOp);
        }
      }
    }

    return delta..chop();
  }

  /// This method joins two Delta together.
  Delta operator +(Delta other) {
    var ops = [..._operations];
    if (other._operations.isNotEmpty) {
      ops.add(other._operations[0]);
      ops.addAll(other._operations.sublist(1));
    }
    return Delta(ops);
  }

  void chop() {
    if (_operations.isEmpty) {
      return;
    }
    _rawString = null;
    final lastOp = _operations.last;
    if (lastOp is TextRetain && (lastOp.attributes?.length ?? 0) == 0) {
      _operations.removeLast();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! Delta) {
      return false;
    }
    return listEquals(_operations, other._operations);
  }

  @override
  int get hashCode {
    return hashList(_operations);
  }

  /// Returned an inverted delta that has the opposite effect of against a base document delta.
  Delta invert(Delta base) {
    final inverted = Delta();
    _operations.fold(0, (int previousValue, op) {
      if (op is TextInsert) {
        inverted.delete(op.length);
      } else if (op is TextRetain && op.attributes == null) {
        inverted.retain(op.length);
        return previousValue + op.length;
      } else if (op is TextDelete || op is TextRetain) {
        final length = op.length;
        final slice = base.slice(previousValue, previousValue + length);
        for (final baseOp in slice._operations) {
          if (op is TextDelete) {
            inverted.add(baseOp);
          } else if (op is TextRetain && op.attributes != null) {
            inverted.retain(baseOp.length,
                invertAttributes(op.attributes, baseOp.attributes));
          }
        }
        return previousValue + length;
      }
      return previousValue;
    });
    return inverted..chop();
  }

  List<dynamic> toJson() {
    return _operations.map((e) => e.toJson()).toList();
  }

  /// This method will return the position of the previous rune.
  ///
  /// Since the encoding of the [String] in Dart is UTF-16.
  /// If you want to find the previous character of a position,
  /// you can' just use the `position - 1` simply.
  ///
  /// This method can help you to compute the position of the previous character.
  int prevRunePosition(int pos) {
    if (pos == 0) {
      return pos - 1;
    }
    _rawString ??=
        _operations.whereType<TextInsert>().map((op) => op.content).join();
    _runeIndexes ??= stringIndexes(_rawString!);
    return _runeIndexes![pos - 1];
  }

  /// This method will return the position of the next rune.
  ///
  /// Since the encoding of the [String] in Dart is UTF-16.
  /// If you want to find the previous character of a position,
  /// you can' just use the `position + 1` simply.
  ///
  /// This method can help you to compute the position of the next character.
  int nextRunePosition(int pos) {
    final stringContent = toRawString();
    if (pos >= stringContent.length - 1) {
      return stringContent.length;
    }
    _runeIndexes ??= stringIndexes(_rawString!);

    for (var i = pos + 1; i < _runeIndexes!.length; i++) {
      if (_runeIndexes![i] != pos) {
        return _runeIndexes![i];
      }
    }

    return stringContent.length;
  }

  String toRawString() {
    _rawString ??=
        _operations.whereType<TextInsert>().map((op) => op.content).join();
    return _rawString!;
  }

  @override
  Iterator<TextOperation> get iterator => _operations.iterator;
}

List<int> stringIndexes(String content) {
  final indexes = List<int>.filled(content.length, 0);
  final iterator = content.runes.iterator;

  while (iterator.moveNext()) {
    for (var i = 0; i < iterator.currentSize; i++) {
      indexes[iterator.rawIndex + i] = iterator.rawIndex;
    }
  }

  return indexes;
}
