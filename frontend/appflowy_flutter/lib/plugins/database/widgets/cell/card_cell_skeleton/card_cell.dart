import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:flutter/material.dart';

abstract class CardCell<T extends CardCellStyle> extends StatefulWidget {
  const CardCell({super.key, required this.style});

  final T style;
}

abstract class CardCellStyle {
  const CardCellStyle({required this.padding});

  final EdgeInsetsGeometry padding;
}

S? isStyleOrNull<S>(CardCellStyle? style) {
  if (style is S) {
    return style as S;
  } else {
    return null;
  }
}

class EditableCardNotifier {
  EditableCardNotifier({bool isEditing = false})
      : isCellEditing = ValueNotifier(isEditing);

  final ValueNotifier<bool> isCellEditing;

  void dispose() {
    isCellEditing.dispose();
  }
}

class EditableRowNotifier {
  EditableRowNotifier({required bool isEditing})
      : isEditing = ValueNotifier(isEditing);

  final Map<CellContext, EditableCardNotifier> _cells = {};
  final ValueNotifier<bool> isEditing;

  void bindCell(
    CellContext cellIdentifier,
    EditableCardNotifier notifier,
  ) {
    assert(
      _cells.values.isEmpty,
      'Only one cell can receive the notification',
    );
    _cells[cellIdentifier]?.dispose();

    notifier.isCellEditing.addListener(() {
      isEditing.value = notifier.isCellEditing.value;
    });

    _cells[cellIdentifier] = notifier;
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

  void unbind() {
    for (final notifier in _cells.values) {
      notifier.dispose();
    }
    _cells.clear();
  }

  void dispose() {
    unbind();
    isEditing.dispose();
  }
}

abstract mixin class EditableCell {
  // Each cell notifier will be bind to the [EditableRowNotifier], which enable
  // the row notifier receive its cells event. For example: begin editing the
  // cell or end editing the cell.
  //
  EditableCardNotifier? get editableNotifier;
}
