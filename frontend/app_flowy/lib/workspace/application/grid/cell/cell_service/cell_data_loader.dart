part of 'cell_service.dart';

abstract class IGridCellDataConfig {
  // The cell data will reload if it receives the field's change notification.
  bool get reloadOnFieldChanged;
}

abstract class ICellDataParser<T> {
  T? parserData(List<int> data);
}

class GridCellDataLoader<T> {
  final CellService service = CellService();
  final GridCellIdentifier cellId;
  final ICellDataParser<T> parser;
  final bool reloadOnFieldChanged;

  GridCellDataLoader({
    required this.cellId,
    required this.parser,
    this.reloadOnFieldChanged = false,
  });

  Future<T?> loadData() {
    final fut = service.getCell(cellId: cellId);
    return fut.then(
      (result) => result.fold((GridCellPB cell) {
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

class StringCellDataParser implements ICellDataParser<String> {
  @override
  String? parserData(List<int> data) {
    final s = utf8.decode(data);
    return s;
  }
}

class DateCellDataParser implements ICellDataParser<DateCellDataPB> {
  @override
  DateCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return DateCellDataPB.fromBuffer(data);
  }
}

class SelectOptionCellDataParser implements ICellDataParser<SelectOptionCellDataPB> {
  @override
  SelectOptionCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return SelectOptionCellDataPB.fromBuffer(data);
  }
}

class URLCellDataParser implements ICellDataParser<URLCellDataPB> {
  @override
  URLCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return URLCellDataPB.fromBuffer(data);
  }
}
