// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

/// Implementation of Quill Delta format in Dart.
library quill_delta;

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:diff_match_patch/diff_match_patch.dart' as dmp;
import 'package:quiver/core.dart';

const _attributeEquality = DeepCollectionEquality();
const _valueEquality = DeepCollectionEquality();

/// Decoder function to convert raw `data` object into a user-defined data type.
///
/// Useful with embedded content.
typedef DataDecoder = Object? Function(Object data);

/// Default data decoder which simply passes through the original value.
Object? _passThroughDataDecoder(Object? data) => data;

/// Operation performed on a rich-text document.
class Operation {
  Operation._(this.key, this.length, this.data, Map? attributes)
      : assert(_validKeys.contains(key), 'Invalid operation key "$key".'),
        assert(() {
          if (key != Operation.insertKey) return true;
          return data is String ? data.length == length : length == 1;
        }(), 'Length of insert operation must be equal to the data length.'),
        _attributes =
            attributes != null ? Map<String, dynamic>.from(attributes) : null;

  /// Creates operation which deletes [length] of characters.
  factory Operation.delete(int length) =>
      Operation._(Operation.deleteKey, length, '', null);

  /// Creates operation which inserts [text] with optional [attributes].
  factory Operation.insert(dynamic data, [Map<String, dynamic>? attributes]) =>
      Operation._(Operation.insertKey, data is String ? data.length : 1, data,
          attributes);

  /// Creates operation which retains [length] of characters and optionally
  /// applies attributes.
  factory Operation.retain(int? length, [Map<String, dynamic>? attributes]) =>
      Operation._(Operation.retainKey, length, '', attributes);

  /// Key of insert operations.
  static const String insertKey = 'insert';

  /// Key of delete operations.
  static const String deleteKey = 'delete';

  /// Key of retain operations.
  static const String retainKey = 'retain';

  /// Key of attributes collection.
  static const String attributesKey = 'attributes';

  static const List<String> _validKeys = [insertKey, deleteKey, retainKey];

  /// Key of this operation, can be "insert", "delete" or "retain".
  final String key;

  /// Length of this operation.
  final int? length;

  /// Payload of "insert" operation, for other types is set to empty string.
  final Object? data;

  /// Rich-text attributes set by this operation, can be `null`.
  Map<String, dynamic>? get attributes =>
      _attributes == null ? null : Map<String, dynamic>.from(_attributes!);
  final Map<String, dynamic>? _attributes;

  /// Creates new [Operation] from JSON payload.
  ///
  /// If `dataDecoder` parameter is not null then it is used to additionally
  /// decode the operation's data object. Only applied to insert operations.
  static Operation fromJson(Map data, {DataDecoder? dataDecoder}) {
    dataDecoder ??= _passThroughDataDecoder;
    final map = Map<String, dynamic>.from(data);
    if (map.containsKey(Operation.insertKey)) {
      final data = dataDecoder(map[Operation.insertKey]);
      final dataLength = data is String ? data.length : 1;
      return Operation._(
          Operation.insertKey, dataLength, data, map[Operation.attributesKey]);
    } else if (map.containsKey(Operation.deleteKey)) {
      final int? length = map[Operation.deleteKey];
      return Operation._(Operation.deleteKey, length, '', null);
    } else if (map.containsKey(Operation.retainKey)) {
      final int? length = map[Operation.retainKey];
      return Operation._(
          Operation.retainKey, length, '', map[Operation.attributesKey]);
    }
    throw ArgumentError.value(data, 'Invalid data for Delta operation.');
  }

  /// Returns JSON-serializable representation of this operation.
  Map<String, dynamic> toJson() {
    final json = {key: value};
    if (_attributes != null) json[Operation.attributesKey] = attributes;
    return json;
  }

  /// Returns value of this operation.
  ///
  /// For insert operations this returns text, for delete and retain - length.
  dynamic get value => (key == Operation.insertKey) ? data : length;

  /// Returns `true` if this is a delete operation.
  bool get isDelete => key == Operation.deleteKey;

  /// Returns `true` if this is an insert operation.
  bool get isInsert => key == Operation.insertKey;

  /// Returns `true` if this is a retain operation.
  bool get isRetain => key == Operation.retainKey;

  /// Returns `true` if this operation has no attributes, e.g. is plain text.
  bool get isPlain => _attributes == null || _attributes!.isEmpty;

  /// Returns `true` if this operation sets at least one attribute.
  bool get isNotPlain => !isPlain;

  /// Returns `true` is this operation is empty.
  ///
  /// An operation is considered empty if its [length] is equal to `0`.
  bool get isEmpty => length == 0;

  /// Returns `true` is this operation is not empty.
  bool get isNotEmpty => length! > 0;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Operation) return false;
    final typedOther = other;
    return key == typedOther.key &&
        length == typedOther.length &&
        _valueEquality.equals(data, typedOther.data) &&
        hasSameAttributes(typedOther);
  }

  /// Returns `true` if this operation has attribute specified by [name].
  bool hasAttribute(String name) =>
      isNotPlain && _attributes!.containsKey(name);

  /// Returns `true` if [other] operation has the same attributes as this one.
  bool hasSameAttributes(Operation other) {
    return _attributeEquality.equals(_attributes, other._attributes);
  }

  @override
  int get hashCode {
    if (_attributes != null && _attributes!.isNotEmpty) {
      final attrsHash =
          hashObjects(_attributes!.entries.map((e) => hash2(e.key, e.value)));
      return hash3(key, value, attrsHash);
    }
    return hash2(key, value);
  }

  @override
  String toString() {
    final attr = attributes == null ? '' : ' + $attributes';
    final text = isInsert
        ? (data is String
            ? (data as String).replaceAll('\n', '⏎')
            : data.toString())
        : '$length';
    return '$key⟨ $text ⟩$attr';
  }
}

/// Delta represents a document or a modification of a document as a sequence of
/// insert, delete and retain operations.
///
/// Delta consisting of only "insert" operations is usually referred to as
/// "document delta". When delta includes also "retain" or "delete" operations
/// it is a "change delta".
class Delta {
  /// Creates new empty [Delta].
  factory Delta() => Delta._(<Operation>[]);

  Delta._(List<Operation> operations) : _operations = operations;

  /// Creates new [Delta] from [other].
  factory Delta.from(Delta other) =>
      Delta._(List<Operation>.from(other._operations));

  // Placeholder char for embed in diff()
  static final String _kNullCharacter = String.fromCharCode(0);

  /// Transforms two attribute sets.
  static Map<String, dynamic>? transformAttributes(
      Map<String, dynamic>? a, Map<String, dynamic>? b, bool priority) {
    if (a == null) return b;
    if (b == null) return null;

    if (!priority) return b;

    final result = b.keys.fold<Map<String, dynamic>>({}, (attributes, key) {
      if (!a.containsKey(key)) attributes[key] = b[key];
      return attributes;
    });

    return result.isEmpty ? null : result;
  }

  /// Composes two attribute sets.
  static Map<String, dynamic>? composeAttributes(
      Map<String, dynamic>? a, Map<String, dynamic>? b,
      {bool keepNull = false}) {
    a ??= const {};
    b ??= const {};

    final result = Map<String, dynamic>.from(a)..addAll(b);
    final keys = result.keys.toList(growable: false);

    if (!keepNull) {
      for (final key in keys) {
        if (result[key] == null) result.remove(key);
      }
    }

    return result.isEmpty ? null : result;
  }

  ///get anti-attr result base on base
  static Map<String, dynamic> invertAttributes(
      Map<String, dynamic>? attr, Map<String, dynamic>? base) {
    attr ??= const {};
    base ??= const {};

    final baseInverted = base.keys.fold({}, (dynamic memo, key) {
      if (base![key] != attr![key] && attr.containsKey(key)) {
        memo[key] = base[key];
      }
      return memo;
    });

    final inverted =
        Map<String, dynamic>.from(attr.keys.fold(baseInverted, (memo, key) {
      if (base![key] != attr![key] && !base.containsKey(key)) {
        memo[key] = null;
      }
      return memo;
    }));
    return inverted;
  }

  /// Returns diff between two attribute sets
  static Map<String, dynamic>? diffAttributes(
      Map<String, dynamic>? a, Map<String, dynamic>? b) {
    a ??= const {};
    b ??= const {};

    final attributes = <String, dynamic>{};
    (a.keys.toList()..addAll(b.keys)).forEach((key) {
      if (a![key] != b![key]) {
        attributes[key] = b.containsKey(key) ? b[key] : null;
      }
    });

    return attributes.keys.isNotEmpty ? attributes : null;
  }

  final List<Operation> _operations;

  int _modificationCount = 0;

  /// Creates [Delta] from de-serialized JSON representation.
  ///
  /// If `dataDecoder` parameter is not null then it is used to additionally
  /// decode the operation's data object. Only applied to insert operations.
  static Delta fromJson(List data, {DataDecoder? dataDecoder}) {
    return Delta._(data
        .map((op) => Operation.fromJson(op, dataDecoder: dataDecoder))
        .toList());
  }

  /// Returns list of operations in this delta.
  List<Operation> toList() => List.from(_operations);

  /// Returns JSON-serializable version of this delta.
  List toJson() => toList().map((operation) => operation.toJson()).toList();

  /// Returns `true` if this delta is empty.
  bool get isEmpty => _operations.isEmpty;

  /// Returns `true` if this delta is not empty.
  bool get isNotEmpty => _operations.isNotEmpty;

  /// Returns number of operations in this delta.
  int get length => _operations.length;

  /// Returns [Operation] at specified [index] in this delta.
  Operation operator [](int index) => _operations[index];

  /// Returns [Operation] at specified [index] in this delta.
  Operation elementAt(int index) => _operations.elementAt(index);

  /// Returns the first [Operation] in this delta.
  Operation get first => _operations.first;

  /// Returns the last [Operation] in this delta.
  Operation get last => _operations.last;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! Delta) return false;
    final typedOther = other;
    const comparator = ListEquality<Operation>(DefaultEquality<Operation>());
    return comparator.equals(_operations, typedOther._operations);
  }

  @override
  int get hashCode => hashObjects(_operations);

  /// Retain [count] of characters from current position.
  void retain(int count, [Map<String, dynamic>? attributes]) {
    assert(count >= 0);
    if (count == 0) return; // no-op
    push(Operation.retain(count, attributes));
  }

  /// Insert [data] at current position.
  void insert(dynamic data, [Map<String, dynamic>? attributes]) {
    if (data is String && data.isEmpty) return; // no-op
    push(Operation.insert(data, attributes));
  }

  /// Delete [count] characters from current position.
  void delete(int count) {
    assert(count >= 0);
    if (count == 0) return;
    push(Operation.delete(count));
  }

  void _mergeWithTail(Operation operation) {
    assert(isNotEmpty);
    assert(last.key == operation.key);
    assert(operation.data is String && last.data is String);

    final length = operation.length! + last.length!;
    final lastText = last.data as String;
    final opText = operation.data as String;
    final resultText = lastText + opText;
    final index = _operations.length;
    _operations.replaceRange(index - 1, index, [
      Operation._(operation.key, length, resultText, operation.attributes),
    ]);
  }

  /// Pushes new operation into this delta.
  ///
  /// Performs compaction by composing [operation] with current tail operation
  /// of this delta, when possible. For instance, if current tail is
  /// `insert('abc')` and pushed operation is `insert('123')` then existing
  /// tail is replaced with `insert('abc123')` - a compound result of the two
  /// operations.
  void push(Operation operation) {
    if (operation.isEmpty) return;

    var index = _operations.length;
    final lastOp = _operations.isNotEmpty ? _operations.last : null;
    if (lastOp != null) {
      if (lastOp.isDelete && operation.isDelete) {
        _mergeWithTail(operation);
        return;
      }

      if (lastOp.isDelete && operation.isInsert) {
        index -= 1; // Always insert before deleting
        final nLastOp = (index > 0) ? _operations.elementAt(index - 1) : null;
        if (nLastOp == null) {
          _operations.insert(0, operation);
          return;
        }
      }

      if (lastOp.isInsert && operation.isInsert) {
        if (lastOp.hasSameAttributes(operation) &&
            operation.data is String &&
            lastOp.data is String) {
          _mergeWithTail(operation);
          return;
        }
      }

      if (lastOp.isRetain && operation.isRetain) {
        if (lastOp.hasSameAttributes(operation)) {
          _mergeWithTail(operation);
          return;
        }
      }
    }
    if (index == _operations.length) {
      _operations.add(operation);
    } else {
      final opAtIndex = _operations.elementAt(index);
      _operations.replaceRange(index, index + 1, [operation, opAtIndex]);
    }
    _modificationCount++;
  }

  /// Composes next operation from [thisIter] and [otherIter].
  ///
  /// Returns new operation or `null` if operations from [thisIter] and
  /// [otherIter] nullify each other. For instance, for the pair `insert('abc')`
  /// and `delete(3)` composition result would be empty string.
  Operation? _composeOperation(
      DeltaIterator thisIter, DeltaIterator otherIter) {
    if (otherIter.isNextInsert) return otherIter.next();
    if (thisIter.isNextDelete) return thisIter.next();

    final length = math.min(thisIter.peekLength(), otherIter.peekLength());
    final thisOp = thisIter.next(length);
    final otherOp = otherIter.next(length);
    assert(thisOp.length == otherOp.length);

    if (otherOp.isRetain) {
      final attributes = composeAttributes(
        thisOp.attributes,
        otherOp.attributes,
        keepNull: thisOp.isRetain,
      );
      if (thisOp.isRetain) {
        return Operation.retain(thisOp.length, attributes);
      } else if (thisOp.isInsert) {
        return Operation.insert(thisOp.data, attributes);
      } else {
        throw StateError('Unreachable');
      }
    } else {
      // otherOp == delete && thisOp in [retain, insert]
      assert(otherOp.isDelete);
      if (thisOp.isRetain) return otherOp;
      assert(thisOp.isInsert);
      // otherOp(delete) + thisOp(insert) => null
    }
    return null;
  }

  /// Composes this delta with [other] and returns new [Delta].
  ///
  /// It is not required for this and [other] delta to represent a document
  /// delta (consisting only of insert operations).
  Delta compose(Delta other) {
    final result = Delta();
    final thisIter = DeltaIterator(this);
    final otherIter = DeltaIterator(other);

    while (thisIter.hasNext || otherIter.hasNext) {
      final newOp = _composeOperation(thisIter, otherIter);
      if (newOp != null) result.push(newOp);
    }
    return result..trim();
  }

  /// Returns a new lazy Iterable with elements that are created by calling
  /// f on each element of this Iterable in iteration order.
  ///
  /// Convenience method
  Iterable<T> map<T>(T Function(Operation) f) {
    return _operations.map<T>(f);
  }

  /// Returns a [Delta] containing differences between 2 [Delta]s.
  /// If [cleanupSemantic] is `true` (default), applies the following:
  ///
  /// The diff of "mouse" and "sofas" is
  ///   [delete(1), insert("s"), retain(1),
  ///   delete("u"), insert("fa"), retain(1), delete(1)].
  /// While this is the optimum diff, it is difficult for humans to understand.
  /// Semantic cleanup rewrites the diff,
  /// expanding it into a more intelligible format.
  /// The above example would become: [(-1, "mouse"), (1, "sofas")].
  /// (source: https://github.com/google/diff-match-patch/wiki/API)
  ///
  /// Useful when one wishes to display difference between 2 documents
  Delta diff(Delta other, {bool cleanupSemantic = true}) {
    if (_operations.equals(other._operations)) {
      return Delta();
    }
    final stringThis = map((op) {
      if (op.isInsert) {
        return op.data is String ? op.data : _kNullCharacter;
      }
      final prep = this == other ? 'on' : 'with';
      throw ArgumentError('diff() call $prep non-document');
    }).join();
    final stringOther = other.map((op) {
      if (op.isInsert) {
        return op.data is String ? op.data : _kNullCharacter;
      }
      final prep = this == other ? 'on' : 'with';
      throw ArgumentError('diff() call $prep non-document');
    }).join();

    final retDelta = Delta();
    final diffResult = dmp.diff(stringThis, stringOther);
    if (cleanupSemantic) {
      dmp.DiffMatchPatch().diffCleanupSemantic(diffResult);
    }

    final thisIter = DeltaIterator(this);
    final otherIter = DeltaIterator(other);

    diffResult.forEach((component) {
      var length = component.text.length;
      while (length > 0) {
        var opLength = 0;
        switch (component.operation) {
          case dmp.DIFF_INSERT:
            opLength = math.min(otherIter.peekLength(), length);
            retDelta.push(otherIter.next(opLength));
            break;
          case dmp.DIFF_DELETE:
            opLength = math.min(length, thisIter.peekLength());
            thisIter.next(opLength);
            retDelta.delete(opLength);
            break;
          case dmp.DIFF_EQUAL:
            opLength = math.min(
              math.min(thisIter.peekLength(), otherIter.peekLength()),
              length,
            );
            final thisOp = thisIter.next(opLength);
            final otherOp = otherIter.next(opLength);
            if (thisOp.data == otherOp.data) {
              retDelta.retain(
                opLength,
                diffAttributes(thisOp.attributes, otherOp.attributes),
              );
            } else {
              retDelta
                ..push(otherOp)
                ..delete(opLength);
            }
            break;
        }
        length -= opLength;
      }
    });
    return retDelta..trim();
  }

  /// Transforms next operation from [otherIter] against next operation in
  /// [thisIter].
  ///
  /// Returns `null` if both operations nullify each other.
  Operation? _transformOperation(
      DeltaIterator thisIter, DeltaIterator otherIter, bool priority) {
    if (thisIter.isNextInsert && (priority || !otherIter.isNextInsert)) {
      return Operation.retain(thisIter.next().length);
    } else if (otherIter.isNextInsert) {
      return otherIter.next();
    }

    final length = math.min(thisIter.peekLength(), otherIter.peekLength());
    final thisOp = thisIter.next(length);
    final otherOp = otherIter.next(length);
    assert(thisOp.length == otherOp.length);

    // At this point only delete and retain operations are possible.
    if (thisOp.isDelete) {
      // otherOp is either delete or retain, so they nullify each other.
      return null;
    } else if (otherOp.isDelete) {
      return otherOp;
    } else {
      // Retain otherOp which is either retain or insert.
      return Operation.retain(
        length,
        transformAttributes(thisOp.attributes, otherOp.attributes, priority),
      );
    }
  }

  /// Transforms [other] delta against operations in this delta.
  Delta transform(Delta other, bool priority) {
    final result = Delta();
    final thisIter = DeltaIterator(this);
    final otherIter = DeltaIterator(other);

    while (thisIter.hasNext || otherIter.hasNext) {
      final newOp = _transformOperation(thisIter, otherIter, priority);
      if (newOp != null) result.push(newOp);
    }
    return result..trim();
  }

  /// Removes trailing retain operation with empty attributes, if present.
  void trim() {
    if (isNotEmpty) {
      final last = _operations.last;
      if (last.isRetain && last.isPlain) _operations.removeLast();
    }
  }

  /// Concatenates [other] with this delta and returns the result.
  Delta concat(Delta other) {
    final result = Delta.from(this);
    if (other.isNotEmpty) {
      // In case first operation of other can be merged with last operation in
      // our list.
      result.push(other._operations.first);
      result._operations.addAll(other._operations.sublist(1));
    }
    return result;
  }

  /// Inverts this delta against [base].
  ///
  /// Returns new delta which negates effect of this delta when applied to
  /// [base]. This is an equivalent of "undo" operation on deltas.
  Delta invert(Delta base) {
    final inverted = Delta();
    if (base.isEmpty) return inverted;

    var baseIndex = 0;
    for (final op in _operations) {
      if (op.isInsert) {
        inverted.delete(op.length!);
      } else if (op.isRetain && op.isPlain) {
        inverted.retain(op.length!);
        baseIndex += op.length!;
      } else if (op.isDelete || (op.isRetain && op.isNotPlain)) {
        final length = op.length!;
        final sliceDelta = base.slice(baseIndex, baseIndex + length);
        sliceDelta.toList().forEach((baseOp) {
          if (op.isDelete) {
            inverted.push(baseOp);
          } else if (op.isRetain && op.isNotPlain) {
            final invertAttr =
                invertAttributes(op.attributes, baseOp.attributes);
            inverted.retain(
                baseOp.length!, invertAttr.isEmpty ? null : invertAttr);
          }
        });
        baseIndex += length;
      } else {
        throw StateError('Unreachable');
      }
    }
    inverted.trim();
    return inverted;
  }

  /// Returns slice of this delta from [start] index (inclusive) to [end]
  /// (exclusive).
  Delta slice(int start, [int? end]) {
    final delta = Delta();
    var index = 0;
    final opIterator = DeltaIterator(this);

    final actualEnd = end ?? DeltaIterator.maxLength;

    while (index < actualEnd && opIterator.hasNext) {
      Operation op;
      if (index < start) {
        op = opIterator.next(start - index);
      } else {
        op = opIterator.next(actualEnd - index);
        delta.push(op);
      }
      index += op.length!;
    }
    return delta;
  }

  /// Transforms [index] against this delta.
  ///
  /// Any "delete" operation before specified [index] shifts it backward, as
  /// well as any "insert" operation shifts it forward.
  ///
  /// The [force] argument is used to resolve scenarios when there is an
  /// insert operation at the same position as [index]. If [force] is set to
  /// `true` (default) then position is forced to shift forward, otherwise
  /// position stays at the same index. In other words setting [force] to
  /// `false` gives higher priority to the transformed position.
  ///
  /// Useful to adjust caret or selection positions.
  int transformPosition(int index, {bool force = true}) {
    final iter = DeltaIterator(this);
    var offset = 0;
    while (iter.hasNext && offset <= index) {
      final op = iter.next();
      if (op.isDelete) {
        index -= math.min(op.length!, index - offset);
        continue;
      } else if (op.isInsert && (offset < index || force)) {
        index += op.length!;
      }
      offset += op.length!;
    }
    return index;
  }

  @override
  String toString() => _operations.join('\n');
}

/// Specialized iterator for [Delta]s.
class DeltaIterator {
  DeltaIterator(this.delta) : _modificationCount = delta._modificationCount;

  static const int maxLength = 1073741824;

  final Delta delta;
  final int _modificationCount;
  int _index = 0;
  int _offset = 0;

  bool get isNextInsert => nextOperationKey == Operation.insertKey;

  bool get isNextDelete => nextOperationKey == Operation.deleteKey;

  bool get isNextRetain => nextOperationKey == Operation.retainKey;

  String? get nextOperationKey {
    if (_index < delta.length) {
      return delta.elementAt(_index).key;
    } else {
      return null;
    }
  }

  bool get hasNext => peekLength() < maxLength;

  /// Returns length of next operation without consuming it.
  ///
  /// Returns [maxLength] if there is no more operations left to iterate.
  int peekLength() {
    if (_index < delta.length) {
      final operation = delta._operations[_index];
      return operation.length! - _offset;
    }
    return maxLength;
  }

  /// Consumes and returns next operation.
  ///
  /// Optional [length] specifies maximum length of operation to return. Note
  /// that actual length of returned operation may be less than specified value.
  ///
  /// If this iterator reached the end of the Delta then returns a retain
  /// operation with its length set to [maxLength].
  // TODO: Note that we used double.infinity as the default value
  // for length here
  //       but this can now cause a type error since operation length is
  //       expected to be an int. Changing default length to [maxLength] is
  //       a workaround to avoid breaking changes.
  Operation next([int length = maxLength]) {
    if (_modificationCount != delta._modificationCount) {
      throw ConcurrentModificationError(delta);
    }

    if (_index < delta.length) {
      final op = delta.elementAt(_index);
      final opKey = op.key;
      final opAttributes = op.attributes;
      final _currentOffset = _offset;
      final actualLength = math.min(op.length! - _currentOffset, length);
      if (actualLength == op.length! - _currentOffset) {
        _index++;
        _offset = 0;
      } else {
        _offset += actualLength;
      }
      final opData = op.isInsert && op.data is String
          ? (op.data as String)
              .substring(_currentOffset, _currentOffset + actualLength)
          : op.data;
      final opIsNotEmpty =
          opData is String ? opData.isNotEmpty : true; // embeds are never empty
      final opLength = opData is String ? opData.length : 1;
      final opActualLength = opIsNotEmpty ? opLength : actualLength;
      return Operation._(opKey, opActualLength, opData, opAttributes);
    }
    return Operation.retain(length);
  }

  /// Skips [length] characters in source delta.
  ///
  /// Returns last skipped operation, or `null` if there was nothing to skip.
  Operation? skip(int length) {
    var skipped = 0;
    Operation? op;
    while (skipped < length && hasNext) {
      final opLength = peekLength();
      final skip = math.min(length - skipped, opLength);
      op = next(skip);
      skipped += op.length!;
    }
    return op;
  }
}
