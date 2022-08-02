import 'dart:async';
import 'package:flowy_editor/service/service.dart';
import 'package:flutter/material.dart';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/document/state_tree.dart';
import 'package:flowy_editor/operation/operation.dart';
import 'package:flowy_editor/operation/transaction.dart';
import 'package:flowy_editor/undo_manager.dart';

class ApplyOptions {
  /// This flag indicates that
  /// whether the transaction should be recorded into
  /// the undo stack.
  final bool recordUndo;
  final bool recordRedo;
  const ApplyOptions({
    this.recordUndo = true,
    this.recordRedo = false,
  });
}

class EditorState {
  final StateTree document;

  List<Node> selectedNodes = [];

  // Service reference.
  final service = FlowyService();

  final UndoManager undoManager = UndoManager();
  Selection? _cursorSelection;

  Selection? get cursorSelection {
    return _cursorSelection;
  }

  /// add the set reason in the future, don't use setter
  updateCursorSelection(Selection? cursorSelection) {
    // broadcast to other users here
    if (cursorSelection == null) {
      service.selectionService.clearSelection();
    } else {
      service.selectionService.updateSelection(cursorSelection);
    }
    _cursorSelection = cursorSelection;
  }

  Timer? _debouncedSealHistoryItemTimer;

  EditorState({
    required this.document,
  }) {
    undoManager.state = this;
  }

  apply(Transaction transaction,
      [ApplyOptions options = const ApplyOptions()]) {
    for (final op in transaction.operations) {
      _applyOperation(op);
    }
    updateCursorSelection(transaction.afterSelection);

    if (options.recordUndo) {
      final undoItem = undoManager.getUndoHistoryItem();
      undoItem.addAll(transaction.operations);
      if (undoItem.beforeSelection == null &&
          transaction.beforeSelection != null) {
        undoItem.beforeSelection = transaction.beforeSelection;
      }
      undoItem.afterSelection = transaction.afterSelection;
      _debouncedSealHistoryItem();
    } else if (options.recordRedo) {
      final redoItem = HistoryItem();
      redoItem.addAll(transaction.operations);
      redoItem.beforeSelection = transaction.beforeSelection;
      redoItem.afterSelection = transaction.afterSelection;
      undoManager.redoStack.push(redoItem);
    }
  }

  _debouncedSealHistoryItem() {
    _debouncedSealHistoryItemTimer?.cancel();
    _debouncedSealHistoryItemTimer =
        Timer(const Duration(milliseconds: 1000), () {
      if (undoManager.undoStack.isNonEmpty) {
        debugPrint('Seal history item');
        final last = undoManager.undoStack.last;
        last.seal();
      }
    });
  }

  _applyOperation(Operation op) {
    if (op is InsertOperation) {
      document.insert(op.path, op.nodes);
    } else if (op is UpdateOperation) {
      document.update(op.path, op.attributes);
    } else if (op is DeleteOperation) {
      document.delete(op.path, op.nodes.length);
    } else if (op is TextEditOperation) {
      document.textEdit(op.path, op.delta);
    }
  }
}
