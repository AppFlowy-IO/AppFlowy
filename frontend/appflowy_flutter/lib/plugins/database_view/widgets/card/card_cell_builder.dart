import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:flutter/material.dart';

import '../../../application/cell/cell_service.dart';
import 'card_cell.dart';
import 'checkbox_card_cell.dart';
import 'checklist_card_cell.dart';
import 'date_card_cell.dart';
import 'number_card_cell.dart';
import 'select_option_card_cell.dart';
import 'text_card_cell.dart';
import 'url_card_cell.dart';

// T represents as the Generic card data
class CardCellBuilder<T> {
  final CellCache cellCache;

  CardCellBuilder(this.cellCache);

  Widget buildCell({
    T? cardData,
    required CellIdentifier cellId,
    EditableCardNotifier? cellNotifier,
    RenderHookByFieldType<T>? renderHooks,
  }) {
    final cellControllerBuilder = CellControllerBuilder(
      cellId: cellId,
      cellCache: cellCache,
    );

    final key = cellId.key();
    switch (cellId.fieldType) {
      case FieldType.Checkbox:
        return CheckboxCardCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.DateTime:
        return DateCardCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.SingleSelect:
        return SelectOptionCardCell<T>(
          renderHook: renderHooks?[FieldType.SingleSelect],
          cellControllerBuilder: cellControllerBuilder,
          cardData: cardData,
          key: key,
        );
      case FieldType.MultiSelect:
        return SelectOptionCardCell<T>(
          renderHook: renderHooks?[FieldType.MultiSelect],
          cellControllerBuilder: cellControllerBuilder,
          cardData: cardData,
          editableNotifier: cellNotifier,
          key: key,
        );
      case FieldType.Checklist:
        return ChecklistCardCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.Number:
        return NumberCardCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.RichText:
        return TextCardCell(
          cellControllerBuilder: cellControllerBuilder,
          editableNotifier: cellNotifier,
          key: key,
        );
      case FieldType.URL:
        return URLCardCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
    }
    throw UnimplementedError;
  }
}
