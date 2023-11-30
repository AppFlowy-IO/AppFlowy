import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:flutter/material.dart';

typedef CellRenderHook<C, CustomCardData> = Widget? Function(
  C cellData,
  CustomCardData cardData,
  BuildContext buildContext,
);
typedef RenderHookByFieldType<C> = Map<FieldType, CellRenderHook<dynamic, C>>;

/// The [RowCardRenderHook] is used to customize the rendering of the
///  card cell. Each cell has its own field type. So the [renderHook]
///  is a map of [FieldType] to [CellRenderHook].
class RowCardRenderHook<CustomCardData> {
  final RenderHookByFieldType<CustomCardData> renderHook = {};
  RowCardRenderHook();

  /// Add render hook for the FieldType.SingleSelect and FieldType.MultiSelect
  void addSelectOptionHook(
    CellRenderHook<List<SelectOptionPB>, CustomCardData?> hook,
  ) {
    final hookFn = _typeSafeHook<List<SelectOptionPB>>(hook);
    renderHook[FieldType.SingleSelect] = hookFn;
    renderHook[FieldType.MultiSelect] = hookFn;
  }

  /// Add a render hook for the [FieldType.RichText]
  void addTextCellHook(
    CellRenderHook<String, CustomCardData?> hook,
  ) {
    renderHook[FieldType.RichText] = _typeSafeHook<String>(hook);
  }

  /// Add a render hook for the [FieldType.Number]
  void addNumberCellHook(
    CellRenderHook<String, CustomCardData?> hook,
  ) {
    renderHook[FieldType.Number] = _typeSafeHook<String>(hook);
  }

  /// Add a render hook for the [FieldType.Date]
  void addDateCellHook(
    CellRenderHook<DateCellDataPB, CustomCardData?> hook,
  ) {
    renderHook[FieldType.DateTime] = _typeSafeHook<DateCellDataPB>(hook);
  }

  /// Add a render hook for [FieldType.LastEditedTime] and [FieldType.CreatedTime]
  void addTimestampCellHook(
    CellRenderHook<TimestampCellDataPB, CustomCardData?> hook,
  ) {
    renderHook[FieldType.LastEditedTime] =
        _typeSafeHook<TimestampCellDataPB>(hook);
    renderHook[FieldType.CreatedTime] =
        _typeSafeHook<TimestampCellDataPB>(hook);
  }

  CellRenderHook<dynamic, CustomCardData> _typeSafeHook<C>(
    CellRenderHook<C, CustomCardData?> hook,
  ) {
    hookFn(cellData, cardData, buildContext) {
      if (cellData == null) {
        return null;
      }

      if (cellData is C) {
        return hook(cellData, cardData, buildContext);
      } else {
        Log.debug("Unexpected cellData type: ${cellData.runtimeType}");
        return null;
      }
    }

    return hookFn;
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
    DatabaseCellContext cellIdentifier,
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

class EditableCellId {
  String fieldId;
  RowId rowId;

  EditableCellId(this.rowId, this.fieldId);

  factory EditableCellId.from(DatabaseCellContext cellIdentifier) =>
      EditableCellId(
        cellIdentifier.rowId,
        cellIdentifier.fieldId,
      );
}
