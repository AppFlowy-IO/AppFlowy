import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';

import 'board_checkbox_cell.dart';
import 'board_date_cell.dart';
import 'board_number_cell.dart';
import 'board_select_option_cell.dart';
import 'board_text_cell.dart';
import 'board_url_cell.dart';

abstract class BoardCellBuilderDelegate
    extends GridCellControllerBuilderDelegate {
  GridCellCache get cellCache;
}

class BoardCellBuilder {
  final BoardCellBuilderDelegate delegate;

  BoardCellBuilder(this.delegate);

  Widget buildCell(GridCellIdentifier cellId) {
    final cellControllerBuilder = GridCellControllerBuilder(
      delegate: delegate,
      cellId: cellId,
      cellCache: delegate.cellCache,
    );

    final key = cellId.key();
    switch (cellId.fieldType) {
      case FieldType.Checkbox:
        return BoardCheckboxCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.DateTime:
        return BoardDateCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.SingleSelect:
        return BoardSelectOptionCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.MultiSelect:
        return BoardSelectOptionCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.Number:
        return BoardNumberCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.RichText:
        return BoardTextCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
      case FieldType.URL:
        return BoardUrlCell(
          cellControllerBuilder: cellControllerBuilder,
          key: key,
        );
    }
    throw UnimplementedError;
  }
}
