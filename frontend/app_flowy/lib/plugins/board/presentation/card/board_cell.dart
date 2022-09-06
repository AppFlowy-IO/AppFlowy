import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:flowy_infra/notifier.dart';

abstract class FocusableBoardCell {
  set becomeFocus(bool isFocus);
}

class EditableCellNotifier {
  final Notifier becomeFirstResponder = Notifier();

  final Notifier resignFirstResponder = Notifier();

  EditableCellNotifier();
}

class EditableRowNotifier {
  final Map<EditableCellId, EditableCellNotifier> _cells = {};

  void insertCell(
    GridCellIdentifier cellIdentifier,
    EditableCellNotifier notifier,
  ) {
    _cells[EditableCellId.from(cellIdentifier)] = notifier;
  }

  void becomeFirstResponder() {
    for (final notifier in _cells.values) {
      notifier.becomeFirstResponder.notify();
    }
  }

  void resignFirstResponder() {
    for (final notifier in _cells.values) {
      notifier.resignFirstResponder.notify();
    }
  }

  void clear() {
    _cells.clear();
  }

  void dispose() {
    for (final notifier in _cells.values) {
      notifier.resignFirstResponder.notify();
    }

    _cells.clear();
  }
}

abstract class EditableCell {
  EditableCellNotifier? get editableNotifier;
}

class EditableCellId {
  String fieldId;
  String rowId;

  EditableCellId(this.rowId, this.fieldId);

  factory EditableCellId.from(GridCellIdentifier cellIdentifier) =>
      EditableCellId(
        cellIdentifier.rowId,
        cellIdentifier.fieldId,
      );
}
