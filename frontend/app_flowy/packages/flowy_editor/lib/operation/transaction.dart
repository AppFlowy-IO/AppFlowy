import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flowy_editor/document/selection.dart';
import './operation.dart';

/// This class to use to store the **changes**
/// will be applied to the editor.
///
/// This class is immutable version the the class
/// [[Transaction]]. Is used to stored and
/// transmit. If you want to build the transaction,
/// use [[Transaction]] directly.
///
/// There will be several ways to consume the transaction:
/// 1. Apply to the state to update the UI.
/// 2. Send to the backend to store and do operation transforming.
/// 3. Stored by the UndoManager to implement redo/undo.
///
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
}
