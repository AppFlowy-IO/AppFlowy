import 'dart:convert';

import 'package:appflowy/plugins/database/domain/cell_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

import 'cell_controller.dart';

abstract class IGridCellDataConfig {
  // The cell data will reload if it receives the field's change notification.
  bool get reloadOnFieldChanged;
}

abstract class CellDataParser<T> {
  T? parserData(List<int> data);
}

class CellDataLoader<T> {
  CellDataLoader({
    required this.parser,
    this.reloadOnFieldChange = false,
  });

  final CellDataParser<T> parser;

  /// Reload the cell data if the field is changed.
  final bool reloadOnFieldChange;

  Future<T?> loadData({
    required String viewId,
    required CellContext cellContext,
  }) {
    return CellBackendService.getCell(
      viewId: viewId,
      cellContext: cellContext,
    ).then(
      (result) => result.fold(
        (CellPB cell) {
          try {
            // Return null if the data of the cell is empty.
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

class CheckboxCellDataParser implements CellDataParser<CheckboxCellDataPB> {
  @override
  CheckboxCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return CheckboxCellDataPB.fromBuffer(data);
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

class TimestampCellDataParser implements CellDataParser<TimestampCellDataPB> {
  @override
  TimestampCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    return TimestampCellDataPB.fromBuffer(data);
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

class RelationCellDataParser implements CellDataParser<RelationCellDataPB> {
  @override
  RelationCellDataPB? parserData(List<int> data) {
    return data.isEmpty ? null : RelationCellDataPB.fromBuffer(data);
  }
}
