import 'dart:convert';

import 'package:appflowy/plugins/database/domain/cell_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

import 'cell_controller.dart';

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

class StringCellDataParser implements CellDataParser<String> {
  @override
  String? parserData(List<int> data) {
    try {
      final s = utf8.decode(data);
      return s;
    } catch (e) {
      Log.error("Failed to parse string data: $e");
      return null;
    }
  }
}

class CheckboxCellDataParser implements CellDataParser<CheckboxCellDataPB> {
  @override
  CheckboxCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }

    try {
      return CheckboxCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse checkbox data: $e");
      return null;
    }
  }
}

class NumberCellDataParser implements CellDataParser<String> {
  @override
  String? parserData(List<int> data) {
    try {
      return utf8.decode(data);
    } catch (e) {
      Log.error("Failed to parse number data: $e");
      return null;
    }
  }
}

class DateCellDataParser implements CellDataParser<DateCellDataPB> {
  @override
  DateCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    try {
      return DateCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse date data: $e");
      return null;
    }
  }
}

class TimestampCellDataParser implements CellDataParser<TimestampCellDataPB> {
  @override
  TimestampCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    try {
      return TimestampCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse timestamp data: $e");
      return null;
    }
  }
}

class SelectOptionCellDataParser
    implements CellDataParser<SelectOptionCellDataPB> {
  @override
  SelectOptionCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    try {
      return SelectOptionCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse select option data: $e");
      return null;
    }
  }
}

class ChecklistCellDataParser implements CellDataParser<ChecklistCellDataPB> {
  @override
  ChecklistCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }

    try {
      return ChecklistCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse checklist data: $e");
      return null;
    }
  }
}

class URLCellDataParser implements CellDataParser<URLCellDataPB> {
  @override
  URLCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    try {
      return URLCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse url data: $e");
      return null;
    }
  }
}

class RelationCellDataParser implements CellDataParser<RelationCellDataPB> {
  @override
  RelationCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }

    try {
      return RelationCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse relation data: $e");
      return null;
    }
  }
}

class TimeCellDataParser implements CellDataParser<TimeCellDataPB> {
  @override
  TimeCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    try {
      return TimeCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse timer data: $e");
      return null;
    }
  }
}

class MediaCellDataParser implements CellDataParser<MediaCellDataPB> {
  @override
  MediaCellDataPB? parserData(List<int> data) {
    if (data.isEmpty) {
      return null;
    }

    try {
      return MediaCellDataPB.fromBuffer(data);
    } catch (e) {
      Log.error("Failed to parse media cell data: $e");
      return null;
    }
  }
}
