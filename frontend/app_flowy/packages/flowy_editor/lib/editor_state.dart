import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/operation/operation.dart';
import 'dart:async';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/undo_manager.dart';
import 'package:flutter/material.dart';

import './document/selection.dart';

class ApplyOptions {
  /// This flag indicates that
  /// whether the transaction should be recorded into
  /// the undo stack.
  final bool recordUndo;
  const ApplyOptions({
    this.recordUndo = true,
  });
}

class EditorState {
  final StateTree document;
  final RenderPlugins renderPlugins;
  List<Node> selectedNodes = [];
  final UndoManager undoManager = UndoManager();
  Selection? cursorSelection;

  Timer? _debouncedSealHistoryItemTimer;

  EditorState({
    required this.document,
    required this.renderPlugins,
  }) {
    undoManager.state = this;
  }

  /// TODO: move to a better place.
  Widget build(BuildContext context) {
    return renderPlugins.buildWidget(
      context: NodeWidgetContext(
        buildContext: context,
        node: document.root,
        editorState: this,
      ),
    );
  }

  apply(Transaction transaction,
      [ApplyOptions options = const ApplyOptions()]) {
    for (final op in transaction.operations) {
      _applyOperation(op);
    }
    cursorSelection = transaction.afterSelection;

    if (options.recordUndo) {
      final undoItem = undoManager.getUndoHistoryItem();
      undoItem.addAll(transaction.operations);
      if (undoItem.beforeSelection == null &&
          transaction.beforeSelection != null) {
        undoItem.beforeSelection = transaction.beforeSelection;
      }
      undoItem.afterSelection = transaction.afterSelection;
      _debouncedSealHistoryItem();
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
      document.insert(op.path, op.value);
    } else if (op is UpdateOperation) {
      document.update(op.path, op.attributes);
    } else if (op is DeleteOperation) {
      document.delete(op.path);
    } else if (op is TextEditOperation) {
      document.textEdit(op.path, op.delta);
    }
  }
}
