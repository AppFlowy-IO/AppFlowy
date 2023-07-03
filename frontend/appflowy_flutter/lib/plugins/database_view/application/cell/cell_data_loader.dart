part of 'cell_service.dart';

abstract class IGridCellDataConfig {
  // The cell data will reload if it receives the field's change notification.
  bool get reloadOnFieldChanged;
}

abstract class CellDataParser<T> {
  T? parserData(List<int> data);
}

class CellDataLoader<T> {
  final CellBackendService service = CellBackendService();
  final DatabaseCellContext cellContext;
  final CellDataParser<T> parser;
  final bool reloadOnFieldChanged;

  CellDataLoader({
    required this.cellContext,
    required this.parser,
    this.reloadOnFieldChanged = false,
  });

  Future<T?> loadData() {
    final fut = service.getCell(cellContext: cellContext);
    return fut.then(
      (result) => result.fold(
        (CellPB cell) {
          try {
            // Return null the data of the cell is empty.
            if (cell.data.isEmpty) {
              return null;
            } else {
              return parser.parserData(cell.data);
            }
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

class StringCellDataParser implements CellDataParser<String> {
  @override
  String? parserData(List<int> data) {
    final s = utf8.decode(data);
    return s;
  }
}

class NumberCellDataParser implements CellDataParser<String> {
  @override
  String? parserData(List<int> data) {
    return utf8.decode(data);
  }
}

class DateCellDataParser implements CellDataParser<DateCellDataPB> {
  @override
  DateCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return DateCellDataPB.fromBuffer(data);
  }
}

class SelectOptionCellDataParser
    implements CellDataParser<SelectOptionCellDataPB> {
  @override
  SelectOptionCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return SelectOptionCellDataPB.fromBuffer(data);
  }
}

class ChecklistCellDataParser implements CellDataParser<ChecklistCellDataPB> {
  @override
  ChecklistCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return ChecklistCellDataPB.fromBuffer(data);
  }
}

class URLCellDataParser implements CellDataParser<URLCellDataPB> {
  @override
  URLCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return URLCellDataPB.fromBuffer(data);
  }
}
