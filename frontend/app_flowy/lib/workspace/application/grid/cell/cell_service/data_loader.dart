part of 'cell_service.dart';

abstract class GridCellDataConfig {
  // The cell data will reload if it receives the field's change notification.
  bool get reloadOnFieldChanged;

  // The cell data will reload if it receives the cell's change notification.
  // For example, the number cell should be reloaded after user input the number.
  // user input: 12
  // cell display: $12
  bool get reloadOnCellChanged;
}

class DefaultCellDataConfig implements GridCellDataConfig {
  @override
  final bool reloadOnCellChanged;

  @override
  final bool reloadOnFieldChanged;

  DefaultCellDataConfig({
    this.reloadOnCellChanged = false,
    this.reloadOnFieldChanged = false,
  });
}

abstract class _GridCellDataLoader<T> {
  Future<T?> loadData();

  GridCellDataConfig get config;
}

class CellDataLoader extends _GridCellDataLoader<Cell> {
  final CellService service = CellService();
  final GridCell gridCell;
  final GridCellDataConfig _config;

  CellDataLoader({
    required this.gridCell,
    bool reloadOnCellChanged = false,
  }) : _config = DefaultCellDataConfig(reloadOnCellChanged: reloadOnCellChanged);

  @override
  Future<Cell?> loadData() {
    final fut = service.getCell(
      gridId: gridCell.gridId,
      fieldId: gridCell.field.id,
      rowId: gridCell.rowId,
    );
    return fut.then((result) {
      return result.fold((data) => data, (err) {
        Log.error(err);
        return null;
      });
    });
  }

  @override
  GridCellDataConfig get config => _config;
}

class DateCellDataLoader extends _GridCellDataLoader<DateCellData> {
  final GridCell gridCell;
  final GridCellDataConfig _config;
  DateCellDataLoader({
    required this.gridCell,
  }) : _config = DefaultCellDataConfig(reloadOnFieldChanged: true);

  @override
  GridCellDataConfig get config => _config;

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

class SelectOptionCellDataLoader extends _GridCellDataLoader<SelectOptionCellData> {
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
  GridCellDataConfig get config => DefaultCellDataConfig();
}
