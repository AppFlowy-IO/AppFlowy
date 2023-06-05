part of 'cell_service.dart';

/// Save the cell data to disk
/// You can extend this class to do custom operations. For example, the DateCellDataPersistence.
abstract class CellDataPersistence<D> {
  Future<Option<FlowyError>> save(final D data);
}

class TextCellDataPersistence implements CellDataPersistence<String> {
  final CellIdentifier cellId;
  final _cellBackendSvc = CellBackendService();

  TextCellDataPersistence({
    required this.cellId,
  });

  @override
  Future<Option<FlowyError>> save(final String data) async {
    final fut = _cellBackendSvc.updateCell(cellId: cellId, data: data);
    return fut.then((final result) {
      return result.fold(
        (final l) => none(),
        (final err) => Some(err),
      );
    });
  }
}

@freezed
class DateCellData with _$DateCellData {
  const factory DateCellData({
    required final DateTime date,
    final String? time,
    required final bool includeTime,
  }) = _DateCellData;
}

class DateCellDataPersistence implements CellDataPersistence<DateCellData> {
  final CellIdentifier cellId;
  DateCellDataPersistence({
    required this.cellId,
  });

  @override
  Future<Option<FlowyError>> save(final DateCellData data) {
    final payload = DateChangesetPB.create()..cellPath = _makeCellPath(cellId);

    final date = (data.date.millisecondsSinceEpoch ~/ 1000).toString();
    payload.date = date;
    payload.isUtc = data.date.isUtc;
    payload.includeTime = data.includeTime;

    if (data.time != null) {
      payload.time = data.time!;
    }

    return DatabaseEventUpdateDateCell(payload).send().then((final result) {
      return result.fold(
        (final l) => none(),
        (final err) => Some(err),
      );
    });
  }
}

CellIdPB _makeCellPath(final CellIdentifier cellId) {
  return CellIdPB.create()
    ..viewId = cellId.viewId
    ..fieldId = cellId.fieldId
    ..rowId = cellId.rowId;
}
