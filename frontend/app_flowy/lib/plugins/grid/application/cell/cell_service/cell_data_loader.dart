part of 'cell_service.dart';

abstract class IGridCellDataConfig {
  // The cell data will reload if it receives the field's change notification.
  bool get reloadOnFieldChanged;
}

abstract class GridCellDataParser<T> {
  T? parserData(List<int> data);
}

class GridCellDataLoader<T> {
  final CellService service = CellService();
  final GridCellIdentifier cellId;
  final GridCellDataParser<T> parser;
  final bool reloadOnFieldChanged;

  GridCellDataLoader({
    required this.cellId,
    required this.parser,
    this.reloadOnFieldChanged = false,
  });

  Future<T?> loadData() {
    final fut = service.getCell(cellId: cellId);
    return fut.then(
      (result) => result.fold(
        (CellPB cell) {
          try {
            return parser.parserData(cell.data);
          } catch (e, s) {
            Log.error('$parser parser cellData failed, $e');
            Log.error('Stack trace \n $s');
            return null;
          }
        },
        (err) {
          Log.error(err);
          return null;
        },
      ),
    );
  }
}

class StringCellDataParser implements GridCellDataParser<String> {
  @override
  String? parserData(List<int> data) {
    final s = utf8.decode(data);
    return s;
  }
}

class DateCellDataParser implements GridCellDataParser<DateCellDataPB> {
  @override
  DateCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return DateCellDataPB.fromBuffer(data);
  }
}

class SelectOptionCellDataParser
    implements GridCellDataParser<SelectOptionCellDataPB> {
  @override
  SelectOptionCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return SelectOptionCellDataPB.fromBuffer(data);
  }
}

class URLCellDataParser implements GridCellDataParser<URLCellDataPB> {
  @override
  URLCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return URLCellDataPB.fromBuffer(data);
  }
}
