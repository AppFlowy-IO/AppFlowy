import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/timestamp_card_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/widgets.dart';

import 'card_cell_skeleton/card_cell.dart';
import 'card_cell_skeleton/checkbox_card_cell.dart';
import 'card_cell_skeleton/checklist_card_cell.dart';
import 'card_cell_skeleton/date_card_cell.dart';
import 'card_cell_skeleton/number_card_cell.dart';
import 'card_cell_skeleton/select_option_card_cell.dart';
import 'card_cell_skeleton/text_card_cell.dart';
import 'card_cell_skeleton/url_card_cell.dart';

typedef CardCellStyleMap = Map<FieldType, CardCellStyle>;

class CardCellBuilder {
  final DatabaseController databaseController;

  CardCellBuilder({required this.databaseController});

  Widget build({
    required CellContext cellContext,
    CardCellStyleMap? styleMap,
    EditableCardNotifier? cellNotifier,
    required bool hasNotes,
  }) {
    final fieldType = databaseController.fieldController
        .getField(cellContext.fieldId)!
        .fieldType;
    final cellController = makeCellController(databaseController, cellContext);
    final key = ValueKey(
      "${databaseController.viewId}${cellContext.fieldId}${cellContext.rowId}",
    );
    final style = styleMap?[fieldType];
    return switch (fieldType) {
      FieldType.Checkbox => CheckboxCardCell(
          key: key,
          style: isStyleOrNull(style),
          cellController: cellController.as(),
        ),
      FieldType.Checklist => ChecklistCardCell(
          key: key,
          style: isStyleOrNull(style),
          cellController: cellController.as(),
        ),
      FieldType.DateTime => DateCardCell(
          key: key,
          style: isStyleOrNull(style),
          cellController: cellController.as(),
        ),
      FieldType.LastEditedTime || FieldType.CreatedTime => TimestampCardCell(
          key: key,
          style: isStyleOrNull(style),
          cellController: cellController.as(),
        ),
      FieldType.SingleSelect || FieldType.MultiSelect => SelectOptionCardCell(
          key: key,
          style: isStyleOrNull(style),
          cellController: cellController.as(),
        ),
      FieldType.Number => NumberCardCell(
          style: isStyleOrNull(style),
          cellController: cellController.as(),
          key: key,
        ),
      FieldType.RichText => TextCardCell(
          key: key,
          style: isStyleOrNull(style),
          cellController: cellController.as(),
          editableNotifier: cellNotifier,
          showNotes: hasNotes,
        ),
      FieldType.URL => URLCardCell(
          key: key,
          style: isStyleOrNull(style),
          cellController: cellController.as(),
        ),
      _ => throw UnimplementedError,
    };
  }
}
