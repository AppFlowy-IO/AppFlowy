import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flutter/material.dart';

abstract class FocusableBoardCell {
  set becomeFocus(bool isFocus);
}

class EditableCellNotifier {
  final Notifier becomeFirstResponder = Notifier();

  final Notifier resignFirstResponder = Notifier();

  final ValueNotifier<bool> isCellEditing;

  EditableCellNotifier({bool isEditing = false})
      : isCellEditing = ValueNotifier(isEditing);

  void dispose() {
    becomeFirstResponder.dispose();
    resignFirstResponder.dispose();
    isCellEditing.dispose();
  }
}

class EditableRowNotifier {
  final Map<EditableCellId, EditableCellNotifier> _cells = {};

  void insertCell(
    GridCellIdentifier cellIdentifier,
    EditableCellNotifier notifier,
  ) {
    final id = EditableCellId.from(cellIdentifier);
    _cells[id]?.dispose();

    notifier.isCellEditing.addListener(() {});

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
    for (final notifier in _cells.values) {
      notifier.dispose();
    }
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
