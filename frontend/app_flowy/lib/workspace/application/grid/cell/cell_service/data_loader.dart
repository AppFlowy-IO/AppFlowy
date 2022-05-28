part of 'cell_service.dart';

abstract class IGridCellDataConfig {
  // The cell data will reload if it receives the field's change notification.
  bool get reloadOnFieldChanged;

  // The cell data will reload if it receives the cell's change notification.
  // For example, the number cell should be reloaded after user input the number.
  // user input: 12
  // cell display: $12
  bool get reloadOnCellChanged;
}

class GridCellDataConfig implements IGridCellDataConfig {
  @override
  final bool reloadOnCellChanged;

  @override
  final bool reloadOnFieldChanged;

  const GridCellDataConfig({
    this.reloadOnCellChanged = false,
    this.reloadOnFieldChanged = false,
  });
}

abstract class IGridCellDataLoader<T> {
  Future<T?> loadData();

  IGridCellDataConfig get config;
}

abstract class ICellDataParser<T> {
  T? parserData();
}

class GridCellDataLoader extends IGridCellDataLoader<String> {
  final CellService service = CellService();
  final GridCell gridCell;

  @override
  final IGridCellDataConfig config;

  GridCellDataLoader({
    required this.gridCell,
    this.config = const GridCellDataConfig(),
  });

  @override
  Future<String> loadData() {
    final fut = service.getCell(
      gridId: gridCell.gridId,
      fieldId: gridCell.field.id,
      rowId: gridCell.rowId,
    );
    return fut.then((result) {
      return result.fold((Cell data) => data.content, (err) {
        Log.error(err);
        return "";
      });
    });
  }
}

class DateCellDataLoader extends IGridCellDataLoader<DateCellData> {
  final GridCell gridCell;
  final IGridCellDataConfig _config;
  DateCellDataLoader({
    required this.gridCell,
  }) : _config = const GridCellDataConfig(reloadOnFieldChanged: true);

  @override
  IGridCellDataConfig get config => _config;

  @override
  Future<DateCellData?> loadData() {
    final payload = CellIdentifierPayload.create()
      ..gridId = gridCell.gridId
      ..fieldId = gridCell.field.id
      ..rowId = gridCell.rowId;

    return GridEventGetDateCellData(payload).send().then((result) {
      return result.fold(
        (data) => data,
        (err) {
          Log.error(err);
          return null;
        },
      );
    });
  }
}

class SelectOptionCellDataLoader extends IGridCellDataLoader<SelectOptionCellData> {
  final SelectOptionService service;
  final GridCell gridCell;
  SelectOptionCellDataLoader({
    required this.gridCell,
  }) : service = SelectOptionService(gridCell: gridCell);
  @override
  Future<SelectOptionCellData?> loadData() async {
    return service.getOpitonContext().then((result) {
      return result.fold(
        (data) => data,
        (err) {
          Log.error(err);
          return null;
        },
      );
    });
  }

  @override
  IGridCellDataConfig get config => const GridCellDataConfig(reloadOnFieldChanged: true);
}
