import 'dart:async';

import 'package:tuple/tuple.dart';

import '../quill_delta.dart';
import '../heuristic/rule.dart';
import '../document/style.dart';
import 'history.dart';
import 'attribute.dart';
import 'node/block.dart';
import 'node/container.dart';
import 'node/embed.dart';
import 'node/line.dart';
import 'node/node.dart';
import 'package:flowy_log/flowy_log.dart';

abstract class EditorChangesetSender {
  void sendDelta(Delta changeset, Delta delta);
}

/// The rich text document
class Document {
  EditorChangesetSender? sender;

  Document({this.sender}) : _delta = Delta()..insert('\n') {
    _loadDocument(_delta);
  }

  Document.fromJson(List data) : _delta = _transform(Delta.fromJson(data)) {
    _loadDocument(_delta);
  }

  Document.fromDelta(Delta delta) : _delta = delta {
    _loadDocument(_delta);
  }

  /// The root node of the document tree
  final Root _root = Root();

  Root get root => _root;

  int get length => _root.length;

  Delta _delta;

  Delta toDelta() => Delta.from(_delta);

  final Rules _rules = Rules.getInstance();

  final StreamController<Tuple3<Delta, Delta, ChangeSource>> _observer =
      StreamController.broadcast();

  final History _history = History();

  Stream<Tuple3<Delta, Delta, ChangeSource>> get changes => _observer.stream;

  bool get hasUndo => _history.hasUndo;

  bool get hasRedo => _history.hasRedo;

  Delta insert(int index, Object? data, {int replaceLength = 0}) {
    Log.trace('insert $data at $index');
    assert(index >= 0);
    assert(data is String || data is Embeddable);
    if (data is Embeddable) {
      data = data.toJson();
    } else if ((data as String).isEmpty) {
      return Delta();
    }

    final delta = _rules.apply(
      RuleType.INSERT,
      this,
      index,
      data: data,
      length: replaceLength,
    );

    compose(delta, ChangeSource.LOCAL);
    Log.trace('current document $_delta');
    return delta;
  }

  Delta delete(int index, int length) {
    Log.trace('delete $length at $index');
    assert(index >= 0 && length > 0);
    final delta = _rules.apply(RuleType.DELETE, this, index, length: length);
    if (delta.isNotEmpty) {
      compose(delta, ChangeSource.LOCAL);
    }
    Log.trace('current document $_delta');
    return delta;
  }

  Delta replace(int index, int length, Object? data) {
    Log.trace('replace $length at $index with $data');
    assert(index >= 0);
    assert(data is String || data is Embeddable);

    final dataIsNotEmpty = (data is String) ? data.isNotEmpty : true;
    assert(dataIsNotEmpty || length > 0);

    var delta = Delta();

    // We have to insert before applying delete rules
    // Otherwise delete would be operating on stale document snapshot.
    if (dataIsNotEmpty) {
      delta = insert(index, data, replaceLength: length);
    }

    if (length > 0) {
      final deleteDelta = delete(index, length);
      delta = delta.compose(deleteDelta);
    }

    Log.trace('current document $delta');
    return delta;
  }

  Delta format(int index, int length, Attribute? attribute) {
    assert(index >= 0 && length >= 0 && attribute != null);
    Log.trace('format $length at $index with $attribute');
    var delta = Delta();

    final formatDelta = _rules.apply(
      RuleType.FORMAT,
      this,
      index,
      length: length,
      attribute: attribute,
    );
    if (formatDelta.isNotEmpty) {
      compose(formatDelta, ChangeSource.LOCAL);
      Log.trace('current document $_delta');
      delta = delta.compose(formatDelta);
    }

    return delta;
  }

  Style collectStyle(int index, int length) {
    final res = queryChild(index);
    return (res.node as Line).collectStyle(res.offset, length);
  }

  ChildQuery queryChild(int offset) {
    final res = _root.queryChild(offset, true);
    if (res.node is Line) {
      return res;
    }
    final block = res.node as Block;
    return block.queryChild(res.offset, true);
  }

  Tuple2 undo() => _history.undo(this);

  Tuple2 redo() => _history.redo(this);

  void compose(Delta delta, ChangeSource changeSource) {
    assert(!_observer.isClosed);
    delta.trim();
    assert(delta.isNotEmpty);

    var offset = 0;
    delta = _transform(delta);
    final originDelta = toDelta();
    for (final op in delta.toList()) {
      final style =
          op.attributes != null ? Style.fromJson(op.attributes) : null;

      if (op.isInsert) {
        _root.insert(offset, _normalize(op.data), style);
      } else if (op.isDelete) {
        _root.delete(offset, op.length);
      } else if (op.attributes != null) {
        _root.retain(offset, op.length, style);
      }

      if (!op.isDelete) {
        offset += op.length!;
      }
    }

    try {
      final changeset = delta;

      _delta = _delta.compose(delta);

      sender?.sendDelta(changeset, _delta);
    } catch (e) {
      throw '_delta compose failed';
    }

    if (_delta != _root.toDelta()) {
      throw 'Compose failed';
    }
    final change = Tuple3(originDelta, delta, changeSource);
    _observer.add(change);
    _history.handleDocChange(change);
  }

  static Delta _transform(Delta delta) {
    final res = Delta();
    final ops = delta.toList();
    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      res.push(op);
      _handleImageInsert(i, ops, op, res);
    }
    return res;
  }

  static void _handleImageInsert(
      int i, List<Operation> ops, Operation op, Delta res) {
    final nextOpIsImage =
        i + 1 < ops.length && ops[i + 1].isInsert && ops[i + 1].data is! String;
    if (nextOpIsImage && !(op.data as String).endsWith('\n')) {
      res.push(Operation.insert('\n'));
    }
    // Currently embed is equivalent to image and hence `is! String`
    final opInsertImage = op.isInsert && op.data is! String;
    final nextOpIsLineBreak = i + 1 < ops.length &&
        ops[i + 1].isInsert &&
        ops[i + 1].data is String &&
        (ops[i + 1].data as String).startsWith('\n');
    if (opInsertImage && (i + 1 == ops.length - 1 || !nextOpIsLineBreak)) {
      // automatically append '\n' for image
      res.push(Operation.insert('\n'));
    }
  }

  Object _normalize(Object? data) {
    if (data is String) {
      return data;
    }

    if (data is Embeddable) {
      return data;
    }
    return Embeddable.fromJson(data as Map<String, dynamic>);
  }

  void close() {
    _observer.close();
    _history.clear();
  }

  void _loadDocument(Delta delta) {
    assert((delta.last.data as String).endsWith('\n'),
        'Delta must ends with a line break.');
    var offset = 0;
    for (final op in delta.toList()) {
      if (!op.isInsert) {
        throw ArgumentError.value(delta,
            'Document Delta can only contain insert operations but ${op.key} found.');
      }
      final style =
          op.attributes != null ? Style.fromJson(op.attributes) : null;
      final data = _normalize(op.data);
      _root.insert(offset, data, style);
      offset += op.length!;
    }
    final node = _root.last;
    if (node is Line &&
        node.parent is! Block &&
        node.style.isEmpty &&
        _root.childCount > 1) {
      _root.remove(node);
    }
  }

  bool isEmpty() {
    if (root.children.length != 1) {
      return false;
    }

    final node = root.children.first;
    if (!node.isLast) {
      return false;
    }

    final delta = node.toDelta();
    return delta.length == 1 &&
        delta.first.data == '\n' &&
        delta.first.key == Operation.insertKey;
  }

  String toPlainText() {
    return root.children.map((child) => child.toPlainText()).join();
  }
}

enum ChangeSource {
  LOCAL,
  REMOTE,
}
