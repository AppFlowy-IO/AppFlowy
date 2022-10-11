import 'dart:async';
import 'package:appflowy_editor/src/infra/log.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_widget.dart';
import 'package:appflowy_editor/src/render/style/editor_style.dart';
import 'package:appflowy_editor/src/service/service.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/core/document/document.dart';
import 'package:appflowy_editor/src/core/transform/operation.dart';
import 'package:appflowy_editor/src/core/transform/transaction.dart';
import 'package:appflowy_editor/src/undo_manager.dart';

class ApplyOptions {
  /// This flag indicates that
  /// whether the transaction should be recorded into
  /// the undo stack
  final bool recordUndo;
  final bool recordRedo;
  const ApplyOptions({
    this.recordUndo = true,
    this.recordRedo = false,
  });
}

enum CursorUpdateReason {
  uiEvent,
  others,
}

/// The state of the editor.
///
/// The state includes:
/// - The document to render
/// - The state of the selection
///
/// [EditorState] also includes the services of the editor:
/// - Selection service
/// - Scroll service
/// - Keyboard service
/// - Input service
/// - Toolbar service
///
/// In consideration of collaborative editing,
/// all the mutations should be applied through [Transaction].
///
/// Mutating the document with document's API is not recommended.
class EditorState {
  final Document document;

  // Service reference.
  final service = FlowyService();

  /// Configures log output parameters,
  /// such as log level and log output callbacks,
  /// with this variable.
  LogConfiguration get logConfiguration => LogConfiguration();

  /// Stores the selection menu items.
  List<SelectionMenuItem> selectionMenuItems = [];

  /// Stores the editor style.
  EditorStyle editorStyle = EditorStyle.defaultStyle();

  /// Operation stream.
  Stream<Operation> get operationStream => _observer.stream;
  final StreamController<Operation> _observer = StreamController.broadcast();

  final UndoManager undoManager = UndoManager();
  Selection? _cursorSelection;

  // TODO: only for testing.
  bool disableSealTimer = false;

  bool editable = true;

  Transaction get transaction {
    if (_transaction != null) {
      return _transaction!;
    }
    _transaction = Transaction(document: document);
    _transaction!.beforeSelection = _cursorSelection;
    return _transaction!;
  }

  Transaction? _transaction;

  void commit() {
    if (_transaction != null) {
      apply(_transaction!, const ApplyOptions(recordUndo: true));
      _transaction = null;
    }
  }

  Selection? get cursorSelection {
    return _cursorSelection;
  }

  RenderBox? get renderBox {
    final renderObject =
        service.scrollServiceKey.currentContext?.findRenderObject();
    if (renderObject != null && renderObject is RenderBox) {
      return renderObject;
    }
    return null;
  }

  updateCursorSelection(Selection? cursorSelection,
      [CursorUpdateReason reason = CursorUpdateReason.others]) {
    // broadcast to other users here
    if (reason != CursorUpdateReason.uiEvent) {
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

  factory EditorState.empty() {
    return EditorState(document: Document.empty());
  }

  /// Apply the transaction to the state.
  ///
  /// The options can be used to determine whether the editor
  /// should record the transaction in undo/redo stack.
  apply(Transaction transaction,
      [ApplyOptions options = const ApplyOptions()]) {
    if (!editable) {
      return;
    }
    // TODO: validate the transation.
    for (final op in transaction.operations) {
      _applyOperation(op);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateCursorSelection(transaction.afterSelection);
    });

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
    if (disableSealTimer) {
      return;
    }
    _debouncedSealHistoryItemTimer?.cancel();
    _debouncedSealHistoryItemTimer =
        Timer(const Duration(milliseconds: 1000), () {
      if (undoManager.undoStack.isNonEmpty) {
        Log.editor.debug('Seal history item');
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
    } else if (op is UpdateTextOperation) {
      document.updateText(op.path, op.delta);
    }
    _observer.add(op);
  }
}
