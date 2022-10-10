import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import '../core/transform/operation.dart';

/// A [Transaction] has a list of [Operation] objects that will be applied
/// to the editor. It is an immutable class and used to store and transmit.
///
/// If you want to build a new [Transaction], use [TransactionBuilder] directly.
///
/// There will be several ways to consume the transaction:
/// 1. Apply to the state to update the UI.
/// 2. Send to the backend to store and do operation transforming.
/// 3. Used by the UndoManager to implement redo/undo.
@immutable
class Transaction {
  final UnmodifiableListView<Operation> operations;
  final Selection? beforeSelection;
  final Selection? afterSelection;

  const Transaction({
    required this.operations,
    this.beforeSelection,
    this.afterSelection,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      "operations": operations.map((e) => e.toJson()),
    };
    if (beforeSelection != null) {
      result["beforeSelection"] = beforeSelection!.toJson();
    }
    if (afterSelection != null) {
      result["afterSelection"] = afterSelection!.toJson();
    }
    return result;
  }
}
