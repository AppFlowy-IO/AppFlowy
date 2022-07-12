import 'package:flowy_editor/operation/operation.dart';

import './document/state_tree.dart';
import './document/selection.dart';
import './operation/operation.dart';
import './operation/transaction.dart';

class EditorState {
  final StateTree document;
  Selection? cursorSelection;

  EditorState({
    required this.document,
  });

  apply(Transaction transaction) {
    for (final op in transaction.operations) {
      _applyOperation(op);
    }
  }

  _applyOperation(Operation op) {
    if (op is InsertOperation) {
      document.insert(op.path, op.value);
    } else if (op is UpdateOperation) {
      document.update(op.path, op.attributes);
    } else if (op is DeleteOperation) {
      document.delete(op.path);
    }
  }

}
