import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';

import 'cell_controller.dart';
import 'cell_service.dart';

typedef TextCellController = CellController<String, String>;
typedef CheckboxCellController = CellController<String, String>;
typedef NumberCellController = CellController<String, String>;
typedef SelectOptionCellController
    = CellController<SelectOptionCellDataPB, String>;
typedef ChecklistCellController = CellController<ChecklistCellDataPB, String>;
typedef DateCellController = CellController<DateCellDataPB, DateCellData>;
typedef URLCellController = CellController<URLCellDataPB, String>;

class CellControllerBuilder {
  final CellIdentifier _cellId;
  final CellCache _cellCache;

  CellControllerBuilder({
    required CellIdentifier cellId,
    required CellCache cellCache,
  })  : _cellCache = cellCache,
        _cellId = cellId;

  CellController build() {
    switch (_cellId.fieldType) {
      case FieldType.Checkbox:
        final cellDataLoader = CellDataLoader(
          cellId: _cellId,
          parser: StringCellDataParser(),
        );
        return TextCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
        );
      case FieldType.DateTime:
      case FieldType.UpdatedAt:
      case FieldType.CreatedAt:
        final cellDataLoader = CellDataLoader(
          cellId: _cellId,
          parser: DateCellDataParser(),
          reloadOnFieldChanged: true,
        );

        return DateCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: DateCellDataPersistence(cellId: _cellId),
        );
      case FieldType.Number:
        final cellDataLoader = CellDataLoader(
          cellId: _cellId,
          parser: NumberCellDataParser(),
          reloadOnFieldChanged: true,
        );
        return NumberCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
        );
      case FieldType.RichText:
        final cellDataLoader = CellDataLoader(
          cellId: _cellId,
          parser: StringCellDataParser(),
        );
        return TextCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        final cellDataLoader = CellDataLoader(
          cellId: _cellId,
          parser: SelectOptionCellDataParser(),
          reloadOnFieldChanged: true,
        );

        return SelectOptionCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
        );

      case FieldType.Checklist:
        final cellDataLoader = CellDataLoader(
          cellId: _cellId,
          parser: ChecklistCellDataParser(),
          reloadOnFieldChanged: true,
        );

        return ChecklistCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
        );
      case FieldType.URL:
        final cellDataLoader = CellDataLoader(
          cellId: _cellId,
          parser: URLCellDataParser(),
        );
        return URLCellController(
          cellId: _cellId,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(cellId: _cellId),
        );
    }
    throw UnimplementedError;
  }
}
