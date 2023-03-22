import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:flutter/material.dart';

import '../../application/cell/cell_service.dart';
import 'cells/card_cell.dart';
import 'cells/checkbox_card_cell.dart';
import 'cells/checklist_card_cell.dart';
import 'cells/date_card_cell.dart';
import 'cells/number_card_cell.dart';
import 'cells/select_option_card_cell.dart';
import 'cells/text_card_cell.dart';
import 'cells/url_card_cell.dart';

// T represents as the Generic card data
class CardCellBuilder<CustomCardData> {
  final CellCache cellCache;

  CardCellBuilder(this.cellCache);

  Widget buildCell({
    CustomCardData? cardData,
    required CellIdentifier cellId,
    EditableCardNotifier? cellNotifier,
    CardConfiguration<CustomCardData>? cardConfiguration,
    Map<FieldType, CardCellStyle>? styles,
  }) {
    final cellControllerBuilder = CellControllerBuilder(
      cellId: cellId,
      cellCache: cellCache,
    );

    final key = cellId.key();
    final style = styles?[cellId.fieldType];
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
        return SelectOptionCardCell<CustomCardData>(
          renderHook: cardConfiguration?.renderHook[FieldType.SingleSelect],
          cellControllerBuilder: cellControllerBuilder,
          cardData: cardData,
          key: key,
        );
      case FieldType.MultiSelect:
        return SelectOptionCardCell<CustomCardData>(
          renderHook: cardConfiguration?.renderHook[FieldType.MultiSelect],
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
          style: isStyleOrNull<TextCardCellStyle>(style),
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
