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
  Map<EditableCellId, EditableCellNotifier> cells = {};

  void insertCell(
    GridCellIdentifier cellIdentifier,
    EditableCellNotifier notifier,
  ) {
    cells[EditableCellId.from(cellIdentifier)] = notifier;
  }

  void becomeFirstResponder() {
    for (final notifier in cells.values) {
      notifier.becomeFirstResponder.notify();
    }
  }

  void resignFirstResponder() {
    for (final notifier in cells.values) {
      notifier.resignFirstResponder.notify();
    }
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
