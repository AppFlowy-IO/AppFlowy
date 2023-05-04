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
    required DateTime date,
    String? time,
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

    final date = (data.date.millisecondsSinceEpoch ~/ 1000).toString();
    payload.date = date;
    payload.isUtc = data.date.isUtc;
    payload.includeTime = data.includeTime;

    if (data.time != null) {
      payload.time = data.time!;
    }

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
