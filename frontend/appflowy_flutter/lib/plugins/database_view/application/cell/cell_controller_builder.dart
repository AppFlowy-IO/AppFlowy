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
  final DatabaseCellContext _cellContext;
  final CellCache _cellCache;

  CellControllerBuilder({
    required DatabaseCellContext cellContext,
    required CellCache cellCache,
  })  : _cellCache = cellCache,
        _cellContext = cellContext;

  CellController build() {
    switch (_cellContext.fieldType) {
      case FieldType.Checkbox:
        final cellDataLoader = CellDataLoader(
          cellContext: _cellContext,
          parser: StringCellDataParser(),
        );
        return TextCellController(
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence:
              TextCellDataPersistence(cellContext: _cellContext),
        );
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        final cellDataLoader = CellDataLoader(
          cellContext: _cellContext,
          parser: DateCellDataParser(),
          reloadOnFieldChanged: true,
        );

        return DateCellController(
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence:
              DateCellDataPersistence(cellContext: _cellContext),
        );
      case FieldType.Number:
        final cellDataLoader = CellDataLoader(
          cellContext: _cellContext,
          parser: NumberCellDataParser(),
          reloadOnFieldChanged: true,
        );
        return NumberCellController(
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence:
              TextCellDataPersistence(cellContext: _cellContext),
        );
      case FieldType.RichText:
        final cellDataLoader = CellDataLoader(
          cellContext: _cellContext,
          parser: StringCellDataParser(),
        );
        return TextCellController(
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence:
              TextCellDataPersistence(cellContext: _cellContext),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        final cellDataLoader = CellDataLoader(
          cellContext: _cellContext,
          parser: SelectOptionCellDataParser(),
          reloadOnFieldChanged: true,
        );

        return SelectOptionCellController(
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence:
              TextCellDataPersistence(cellContext: _cellContext),
        );

      case FieldType.Checklist:
        final cellDataLoader = CellDataLoader(
          cellContext: _cellContext,
          parser: ChecklistCellDataParser(),
          reloadOnFieldChanged: true,
        );

        return ChecklistCellController(
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence:
              TextCellDataPersistence(cellContext: _cellContext),
        );
      case FieldType.URL:
        final cellDataLoader = CellDataLoader(
          cellContext: _cellContext,
          parser: URLCellDataParser(),
        );
        return URLCellController(
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence:
              TextCellDataPersistence(cellContext: _cellContext),
        );
    }
    throw UnimplementedError;
  }
}
