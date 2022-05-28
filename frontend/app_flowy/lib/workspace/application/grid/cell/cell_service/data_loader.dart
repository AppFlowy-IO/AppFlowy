part of 'cell_service.dart';

abstract class IGridCellDataConfig {
  // The cell data will reload if it receives the field's change notification.
  bool get reloadOnFieldChanged;

  // When the reloadOnCellChanged is true, it will load the cell data after user input.
  // For example: The number cell reload the cell data that carries the format
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
  T? parserData(List<int> data);
}

class GridCellDataLoader<T> extends IGridCellDataLoader<T> {
  final CellService service = CellService();
  final GridCell gridCell;
  final ICellDataParser<T> parser;

  @override
  final IGridCellDataConfig config;

  GridCellDataLoader({
    required this.gridCell,
    required this.parser,
    this.config = const GridCellDataConfig(),
  });

  @override
  Future<T?> loadData() {
    final fut = service.getCell(
      gridId: gridCell.gridId,
      fieldId: gridCell.field.id,
      rowId: gridCell.rowId,
    );
    return fut.then(
      (result) => result.fold((Cell cell) {
        try {
          return parser.parserData(cell.data);
        } catch (e, s) {
          Log.error('$parser parser cellData failed, $e');
          Log.error('Stack trace \n $s');
          return null;
        }
      }, (err) {
        Log.error(err);
        return null;
      }),
    );
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

class StringCellDataParser implements ICellDataParser<String> {
  @override
  String? parserData(List<int> data) {
    return utf8.decode(data);
  }
}

class DateCellDataParser implements ICellDataParser<DateCellData> {
  @override
  DateCellData? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return DateCellData.fromBuffer(data);
  }
}

class SelectOptionCellDataParser implements ICellDataParser<SelectOptionCellData> {
  @override
  SelectOptionCellData? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return SelectOptionCellData.fromBuffer(data);
  }
}
