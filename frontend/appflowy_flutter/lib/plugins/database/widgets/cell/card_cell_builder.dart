import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

import 'card_cell_skeleton/card_cell.dart';
import 'card_cell_skeleton/checkbox_card_cell.dart';
import 'card_cell_skeleton/checklist_card_cell.dart';
import 'card_cell_skeleton/date_card_cell.dart';
import 'card_cell_skeleton/media_card_cell.dart';
import 'card_cell_skeleton/number_card_cell.dart';
import 'card_cell_skeleton/relation_card_cell.dart';
import 'card_cell_skeleton/select_option_card_cell.dart';
import 'card_cell_skeleton/summary_card_cell.dart';
import 'card_cell_skeleton/text_card_cell.dart';
import 'card_cell_skeleton/time_card_cell.dart';
import 'card_cell_skeleton/timestamp_card_cell.dart';
import 'card_cell_skeleton/translate_card_cell.dart';
import 'card_cell_skeleton/url_card_cell.dart';

typedef CardCellStyleMap = Map<FieldType, CardCellStyle>;

class CardCellBuilder {
  CardCellBuilder({required this.databaseController});

  final DatabaseController databaseController;

  Widget build({
    required CellContext cellContext,
    required CardCellStyleMap styleMap,
    EditableCardNotifier? cellNotifier,
    Widget? placeholder,
    FocusNode? focusNode,
    bool enableTitleEditing = false,
    required bool hasNotes,
  }) {
    final fieldType = databaseController.fieldController
        .getField(cellContext.fieldId)!
        .fieldType;
    final key = ValueKey(
      "${databaseController.viewId}${cellContext.fieldId}${cellContext.rowId}",
    );
    final style = styleMap[fieldType];
    return switch (fieldType) {
      FieldType.Checkbox => CheckboxCardCell(
          focusNode: focusNode,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.Checklist => ChecklistCardCell(
          placeholder: placeholder,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.DateTime => DateCardCell(
          placeholder: placeholder,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.LastEditedTime || FieldType.CreatedTime => TimestampCardCell(
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.SingleSelect || FieldType.MultiSelect => SelectOptionCardCell(
          placeholder: placeholder,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.Number => NumberCardCell(
          placeholder: placeholder,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
          key: key,
        ),
      FieldType.RichText => TextCardCell(
          enableTitleEditing: enableTitleEditing,
          placeholder: placeholder,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
          editableNotifier: cellNotifier,
          showNotes: hasNotes,
        ),
      FieldType.URL => URLCardCell(
          placeholder: placeholder,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.Relation => RelationCardCell(
          placeholder: placeholder,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.Summary => SummaryCardCell(
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.Time => TimeCardCell(
          placeholder: placeholder,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.Translate => TranslateCardCell(
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      FieldType.Media => MediaCardCell(
          placeholder: placeholder,
          key: key,
          style: isStyleOrNull(style),
          databaseController: databaseController,
          cellContext: cellContext,
        ),
      _ => throw UnimplementedError,
    };
  }
}
