import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:flutter/material.dart';

abstract class FocusableBoardCell {
  set becomeFocus(bool isFocus);
}

class EditableCellNotifier {
  final ValueNotifier<bool> isCellEditing;

  EditableCellNotifier({bool isEditing = false})
      : isCellEditing = ValueNotifier(isEditing);

  void dispose() {
    isCellEditing.dispose();
  }
}

class EditableRowNotifier {
  final Map<EditableCellId, EditableCellNotifier> _cells = {};
  final ValueNotifier<bool> isEditing;

  EditableRowNotifier({required bool isEditing})
      : isEditing = ValueNotifier(isEditing);

  void insertCell(
    GridCellIdentifier cellIdentifier,
    EditableCellNotifier notifier,
  ) {
    assert(
      _cells.values.isEmpty,
      'Only one cell can receive the notification',
    );
    final id = EditableCellId.from(cellIdentifier);
    _cells[id]?.dispose();

    notifier.isCellEditing.addListener(() {
      isEditing.value = notifier.isCellEditing.value;
    });

    _cells[EditableCellId.from(cellIdentifier)] = notifier;
  }

  void becomeFirstResponder() {
    if (_cells.values.isEmpty) return;
    assert(
      _cells.values.length == 1,
      'Only one cell can receive the notification',
    );
    _cells.values.first.isCellEditing.value = true;
  }

  void resignFirstResponder() {
    if (_cells.values.isEmpty) return;
    assert(
      _cells.values.length == 1,
      'Only one cell can receive the notification',
    );
    _cells.values.first.isCellEditing.value = false;
  }

  void clear() {
    for (final notifier in _cells.values) {
      notifier.dispose();
    }
    _cells.clear();
  }

  void dispose() {
    for (final notifier in _cells.values) {
      notifier.dispose();
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
