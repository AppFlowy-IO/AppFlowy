import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

import 'cell_cache.dart';
import 'cell_controller.dart';
import 'cell_data_loader.dart';
import 'cell_data_persistence.dart';

typedef TextCellController = CellController<String, String>;
typedef CheckboxCellController = CellController<String, String>;
typedef NumberCellController = CellController<String, String>;
typedef SelectOptionCellController
    = CellController<SelectOptionCellDataPB, String>;
typedef ChecklistCellController = CellController<ChecklistCellDataPB, String>;
typedef DateCellController = CellController<DateCellDataPB, String>;
typedef TimestampCellController = CellController<TimestampCellDataPB, String>;
typedef URLCellController = CellController<URLCellDataPB, String>;

class CellControllerBuilder {
  final String viewId;
  final FieldController fieldController;
  final CellContext _cellContext;
  final CellMemCache _cellCache;

  CellControllerBuilder({
    required this.fieldController,
    required this.viewId,
    required CellContext cellContext,
    required CellMemCache cellCache,
  })  : _cellCache = cellCache,
        _cellContext = cellContext;

  CellController build() {
    switch (_cellContext.fieldType) {
      case FieldType.Checkbox:
        final cellDataLoader = CellDataLoader(
          viewId: viewId,
          cellContext: _cellContext,
          parser: StringCellDataParser(),
        );
        return TextCellController(
          viewId: viewId,
          fieldController: fieldController,
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(
            viewId: viewId,
            cellContext: _cellContext,
          ),
        );
      case FieldType.DateTime:
        final cellDataLoader = CellDataLoader(
          viewId: viewId,
          cellContext: _cellContext,
          parser: DateCellDataParser(),
          reloadOnFieldChanged: true,
        );
        return DateCellController(
          viewId: viewId,
          fieldController: fieldController,
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(
            viewId: viewId,
            cellContext: _cellContext,
          ),
        );
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        final cellDataLoader = CellDataLoader(
          viewId: viewId,
          cellContext: _cellContext,
          parser: TimestampCellDataParser(),
          reloadOnFieldChanged: true,
        );
        return TimestampCellController(
          viewId: viewId,
          fieldController: fieldController,
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(
            viewId: viewId,
            cellContext: _cellContext,
          ),
        );
      case FieldType.Number:
        final cellDataLoader = CellDataLoader(
          viewId: viewId,
          cellContext: _cellContext,
          parser: NumberCellDataParser(),
          reloadOnFieldChanged: true,
        );
        return NumberCellController(
          viewId: viewId,
          fieldController: fieldController,
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(
            viewId: viewId,
            cellContext: _cellContext,
          ),
        );
      case FieldType.RichText:
        final cellDataLoader = CellDataLoader(
          viewId: viewId,
          cellContext: _cellContext,
          parser: StringCellDataParser(),
        );
        return TextCellController(
          viewId: viewId,
          fieldController: fieldController,
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(
            viewId: viewId,
            cellContext: _cellContext,
          ),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        final cellDataLoader = CellDataLoader(
          viewId: viewId,
          cellContext: _cellContext,
          parser: SelectOptionCellDataParser(),
          reloadOnFieldChanged: true,
        );
        return SelectOptionCellController(
          viewId: viewId,
          fieldController: fieldController,
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(
            viewId: viewId,
            cellContext: _cellContext,
          ),
        );
      case FieldType.Checklist:
        final cellDataLoader = CellDataLoader(
          viewId: viewId,
          cellContext: _cellContext,
          parser: ChecklistCellDataParser(),
          reloadOnFieldChanged: true,
        );
        return ChecklistCellController(
          viewId: viewId,
          fieldController: fieldController,
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(
            viewId: viewId,
            cellContext: _cellContext,
          ),
        );
      case FieldType.URL:
        final cellDataLoader = CellDataLoader(
          viewId: viewId,
          cellContext: _cellContext,
          parser: URLCellDataParser(),
        );
        return URLCellController(
          viewId: viewId,
          fieldController: fieldController,
          cellContext: _cellContext,
          cellCache: _cellCache,
          cellDataLoader: cellDataLoader,
          cellDataPersistence: TextCellDataPersistence(
            viewId: viewId,
            cellContext: _cellContext,
          ),
        );
    }
    throw UnimplementedError;
  }
}
