import 'dart:collection';

import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/infra/log.dart';
import 'package:appflowy_editor/src/operation/operation.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/operation/transaction.dart';
import 'package:appflowy_editor/src/editor_state.dart';

/// A [HistoryItem] contains list of operations committed by users.
/// If a [HistoryItem] is not sealed, operations can be added sequentially.
/// Otherwise, the operations should be added to a new [HistoryItem].
class HistoryItem extends LinkedListEntry<HistoryItem> {
  final List<Operation> operations = [];
  Selection? beforeSelection;
  Selection? afterSelection;
  bool _sealed = false;

  HistoryItem();

  /// Seal the history item.
  /// When an item is sealed, no more operations can be added
  /// to the item.
  ///
  /// The caller should create a new [HistoryItem].
  seal() {
    _sealed = true;
  }

  bool get sealed => _sealed;

  add(Operation op) {
    operations.add(op);
  }

  addAll(Iterable<Operation> iterable) {
    operations.addAll(iterable);
  }

  /// Create a new [Transaction] by inverting the operations.
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

  clear() {
    _list.clear();
  }

  HistoryItem get last => _list.last;

  bool get isEmpty => _list.isEmpty;

  bool get isNonEmpty => _list.isNotEmpty;
}

class UndoManager {
  final FixedSizeStack undoStack;
  final FixedSizeStack redoStack;
  EditorState? state;

  UndoManager([int stackSize = 20])
      : undoStack = FixedSizeStack(stackSize),
        redoStack = FixedSizeStack(stackSize);

  HistoryItem getUndoHistoryItem() {
    if (undoStack.isEmpty) {
      final item = HistoryItem();
      undoStack.push(item);
      return item;
    }
    final last = undoStack.last;
    if (last.sealed) {
      redoStack.clear();
      final item = HistoryItem();
      undoStack.push(item);
      return item;
    }
    return last;
  }

  undo() {
    Log.editor.debug('undo');
    final s = state;
    if (s == null) {
      return;
    }
    final historyItem = undoStack.pop();
    if (historyItem == null) {
      return;
    }
    final transaction = historyItem.toTransaction(s);
    s.apply(
        transaction,
        const ApplyOptions(
          recordUndo: false,
          recordRedo: true,
        ));
  }

  redo() {
    Log.editor.debug('redo');
    final s = state;
    if (s == null) {
      return;
    }
    final historyItem = redoStack.pop();
    if (historyItem == null) {
      return;
    }
    final transaction = historyItem.toTransaction(s);
    s.apply(
        transaction,
        const ApplyOptions(
          recordUndo: true,
          recordRedo: false,
        ));
  }
}
