import 'dart:collection';

import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/operation/operation.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/operation/transaction.dart';
import 'package:flowy_editor/editor_state.dart';

class HistoryItem extends LinkedListEntry<HistoryItem> {
  final List<Operation> operations = [];
  Selection? beforeSelection;
  Selection? afterSelection;
  bool _sealed = false;

  HistoryItem();

  seal() {
    _sealed = true;
  }

  add(Operation op) {
    operations.add(op);
  }

  addAll(Iterable<Operation> iterable) {
    operations.addAll(iterable);
  }

  bool get sealed {
    return _sealed;
  }

  Transaction toTransaction(EditorState state) {
    final builder = TransactionBuilder(state);
    for (var i = operations.length - 1; i >= 0; i--) {
      final operation = operations[i];
      final inverted = operation.invert();
      builder.add(inverted);
    }
    builder.afterSelection = beforeSelection;
    builder.beforeSelection = afterSelection;
    return builder.finish();
  }
}

class FixedSizeStack {
  final _list = LinkedList<HistoryItem>();
  final int maxSize;

  FixedSizeStack(this.maxSize);

  push(HistoryItem stackItem) {
    if (_list.length >= maxSize) {
      _list.remove(_list.first);
    }
    _list.add(stackItem);
  }

  HistoryItem? pop() {
    if (_list.isEmpty) {
      return null;
    }
    final last = _list.last;

    _list.remove(last);

    return last;
  }

  HistoryItem get last {
    return _list.last;
  }

  bool get isEmpty {
    return _list.isEmpty;
  }

  bool get isNonEmpty {
    return _list.isNotEmpty;
  }
}

class UndoManager {
  final undoStack = FixedSizeStack(20);
  final redoStack = FixedSizeStack(20);
  EditorState? state;

  HistoryItem getUndoHistoryItem() {
    if (undoStack.isEmpty) {
      final item = HistoryItem();
      undoStack.push(item);
      return item;
    }
    final last = undoStack.last;
    if (last.sealed) {
      final item = HistoryItem();
      undoStack.push(item);
      return item;
    }
    return last;
  }

  undo() {
    final historyItem = undoStack.pop();
    if (historyItem == null) {
      return;
    }
    final transaction = historyItem.toTransaction(state!);
    state!.apply(transaction, const ApplyOptions(noLog: true));
  }
}
