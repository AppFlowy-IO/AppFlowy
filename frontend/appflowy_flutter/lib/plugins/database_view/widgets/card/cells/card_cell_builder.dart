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

abstract class BoardCellBuilderDelegate {
  CellCache get cellCache;
}

class CardCellBuilder {
  final BoardCellBuilderDelegate delegate;

  CardCellBuilder(this.delegate);

  Widget buildCell(
    String groupId,
    CellIdentifier cellId,
    EditableCardNotifier cellNotifier,
  ) {
    final cellControllerBuilder = CellControllerBuilder(
      cellId: cellId,
      cellCache: delegate.cellCache,
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
        return SelectOptionCardCell(
          groupId: groupId,
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.MultiSelect:
        return SelectOptionCardCell(
          groupId: groupId,
          cellControllerBuilder: cellControllerBuilder,
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
