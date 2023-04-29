part of 'cell_service.dart';

/// Save the cell data to disk
/// You can extend this class to do custom operations. For example, the DateCellDataPersistence.
abstract class CellDataPersistence<D> {
  Future<Option<FlowyError>> save(D data);
}

class TextCellDataPersistence implements CellDataPersistence<String> {
  final CellIdentifier cellId;
  final _cellBackendSvc = CellBackendService();

  TextCellDataPersistence({
    required this.cellId,
  });

  @override
  Future<Option<FlowyError>> save(String data) async {
    final fut = _cellBackendSvc.updateCell(cellId: cellId, data: data);
    return fut.then((result) {
      return result.fold(
        (l) => none(),
        (err) => Some(err),
      );
    });
  }
}

@freezed
class DateCellData with _$DateCellData {
  const factory DateCellData({
    required DateTime? dateTime,
    required String? time,
    required bool includeTime,
  }) = _DateCellData;
}

class DateCellDataPersistence implements CellDataPersistence<DateCellData> {
  final CellIdentifier cellId;
  DateCellDataPersistence({
    required this.cellId,
  });

  @override
  Future<Option<FlowyError>> save(DateCellData data) {
    var payload = DateChangesetPB.create()..cellPath = _makeCellPath(cellId);

    if (data.dateTime != null) {
      final date = (data.dateTime!.millisecondsSinceEpoch ~/ 1000).toString();
      payload.date = date;
    }
    if (data.time != null) {
      payload.time = data.time!;
    }
    payload.includeTime = data.includeTime;

    return DatabaseEventUpdateDateCell(payload).send().then((result) {
      return result.fold(
        (l) => none(),
        (err) => Some(err),
      );
    });
  }
}

CellIdPB _makeCellPath(CellIdentifier cellId) {
  return CellIdPB.create()
    ..viewId = cellId.viewId
    ..fieldId = cellId.fieldId
    ..rowId = cellId.rowId;
}
