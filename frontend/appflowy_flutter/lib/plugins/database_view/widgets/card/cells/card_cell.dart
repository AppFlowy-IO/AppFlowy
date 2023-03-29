import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:flutter/material.dart';

typedef CellRenderHook<C, T> = Widget? Function(C cellData, T cardData);
typedef RenderHookByFieldType<C> = Map<FieldType, CellRenderHook<dynamic, C>>;

class CardConfiguration<CustomCardData> {
  final RenderHookByFieldType<CustomCardData> renderHook = {};
  CardConfiguration();

  void addSelectOptionHook(
    CellRenderHook<List<SelectOptionPB>, CustomCardData> hook,
  ) {
    selectOptionHook(cellData, cardData) {
      if (cellData is List<SelectOptionPB>) {
        hook(cellData, cardData);
      }
    }

    renderHook[FieldType.SingleSelect] = selectOptionHook;
    renderHook[FieldType.MultiSelect] = selectOptionHook;
  }
}

abstract class CardCellStyle {}

S? isStyleOrNull<S>(CardCellStyle? style) {
  if (style is S) {
    return style as S;
  } else {
    return null;
  }
}

abstract class CardCell<T, S extends CardCellStyle> extends StatefulWidget {
  final T? cardData;
  final S? style;

  const CardCell({super.key, this.cardData, this.style});
}

class EditableCardNotifier {
  final ValueNotifier<bool> isCellEditing;

  EditableCardNotifier({bool isEditing = false})
      : isCellEditing = ValueNotifier(isEditing);

  void dispose() {
    isCellEditing.dispose();
  }
}

class EditableRowNotifier {
  final Map<EditableCellId, EditableCardNotifier> _cells = {};
  final ValueNotifier<bool> isEditing;

  EditableRowNotifier({required bool isEditing})
      : isEditing = ValueNotifier(isEditing);

  void bindCell(
    CellIdentifier cellIdentifier,
    EditableCardNotifier notifier,
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

  void unbind() {
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
  // Each cell notifier will be bind to the [EditableRowNotifier], which enable
  // the row notifier receive its cells event. For example: begin editing the
  // cell or end editing the cell.
  //
  EditableCardNotifier? get editableNotifier;
}

class EditableCellId {
  String fieldId;
  String rowId;

  EditableCellId(this.rowId, this.fieldId);

  factory EditableCellId.from(CellIdentifier cellIdentifier) => EditableCellId(
        cellIdentifier.rowId,
        cellIdentifier.fieldId,
      );
}
