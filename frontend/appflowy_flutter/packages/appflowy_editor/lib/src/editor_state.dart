import 'dart:async';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/history/undo_manager.dart';

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

  /// Stores the toolbar items.
  List<ToolbarItem> toolbarItems = [];

  /// Operation stream.
  Stream<Transaction> get transactionStream => _observer.stream;
  final StreamController<Transaction> _observer = StreamController.broadcast();

  late ThemeData themeData;
  EditorStyle get editorStyle =>
      themeData.extension<EditorStyle>() ?? EditorStyle.light;

  final UndoManager undoManager = UndoManager();
  Selection? _cursorSelection;

  // TODO: only for testing.
  bool disableSealTimer = false;
  bool disableRules = false;

  bool editable = true;

  Transaction get transaction {
    final transaction = Transaction(document: document);
    transaction.beforeSelection = _cursorSelection;
    return transaction;
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

  Future<void> updateCursorSelection(
    Selection? cursorSelection, [
    CursorUpdateReason reason = CursorUpdateReason.others,
  ]) {
    final completer = Completer<void>();

    // broadcast to other users here
    if (reason != CursorUpdateReason.uiEvent) {
      // service.selectionService.updateSelection(cursorSelection);
      service.selectionServiceV2.selection = cursorSelection;
    }
    _cursorSelection = cursorSelection;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      completer.complete();
    });
    return completer.future;
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
  Future<void> apply(
    Transaction transaction, {
    ApplyOptions options = const ApplyOptions(recordUndo: true),
    ruleCount = 0,
    withUpdateCursor = true,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final completer = Completer<void>();

    if (!editable) {
      completer.complete();
      return completer.future;
    }
    // TODO: validate the transaction.
    for (final op in transaction.operations) {
      _applyOperation(op);
    }

    _observer.add(transaction);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _applyRules(ruleCount);
      if (withUpdateCursor) {
        await updateCursorSelection(transaction.afterSelection);
      }
      stopWatch.stop();
      print(
        '[EditorState] apply transaction: ${stopWatch.elapsedMilliseconds}ms',
      );
      completer.complete();
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

    return completer.future;
  }

  List<Node> getNodesInSelection(Selection selection) {
    final start = selection.normalized.start.path;
    final end = selection.normalized.end.path;
    assert(start <= end);
    final startNode = document.nodeAtPath(start);
    final endNode = document.nodeAtPath(end);
    if (startNode != null && endNode != null) {
      final nodes = NodeIterator(
        document: document,
        startNode: startNode,
        endNode: endNode,
      ).toList();
      if (selection.isBackward) {
        return nodes;
      } else {
        return nodes.reversed.toList(growable: false);
      }
    }
    return [];
  }

  void _debouncedSealHistoryItem() {
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

  void _applyOperation(Operation op) {
    if (op is InsertOperation) {
      document.insert(op.path, op.nodes);
    } else if (op is UpdateOperation) {
      document.update(op.path, op.attributes);
    } else if (op is DeleteOperation) {
      document.delete(op.path, op.nodes.length);
    } else if (op is UpdateTextOperation) {
      document.updateText(op.path, op.delta);
    }
  }

  void _applyRules(int ruleCount) {
    // Set a maximum count to prevent a dead loop.
    if (ruleCount >= 5 || disableRules) {
      return;
    }

    final tr = transaction;

    // Rules
    _insureLastNodeEditable(tr);

    if (tr.operations.isNotEmpty) {
      apply(tr, ruleCount: ruleCount + 1, withUpdateCursor: false);
    }
  }

  void _insureLastNodeEditable(Transaction tr) {
    if (document.root.children.isEmpty ||
        document.root.children.last.id != 'paragraph') {
      tr.insertNode(
        [document.root.children.length],
        Node(type: 'paragraph', attributes: {'texts': []}),
      );
    }
  }
}
