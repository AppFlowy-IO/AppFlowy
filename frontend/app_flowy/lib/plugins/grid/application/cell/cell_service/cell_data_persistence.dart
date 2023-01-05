part of 'cell_service.dart';

/// Save the cell data to disk
/// You can extend this class to do custom operations. For example, the DateCellDataPersistence.
abstract class IGridCellDataPersistence<D> {
  Future<Option<FlowyError>> save(D data);
}

class CellDataPersistence implements IGridCellDataPersistence<String> {
  final GridCellIdentifier cellId;

  CellDataPersistence({
    required this.cellId,
  });
  final CellService _cellService = CellService();

  @override
  Future<Option<FlowyError>> save(String data) async {
    final fut = _cellService.updateCell(cellId: cellId, data: data);

    return fut.then((result) {
      return result.fold(
        (l) => none(),
        (err) => Some(err),
      );
    });
  }
}

@freezed
class CalendarData with _$CalendarData {
  const factory CalendarData({required DateTime date, String? time}) =
      _CalendarData;
}

class DateCellDataPersistence
    implements IGridCellDataPersistence<CalendarData> {
  final GridCellIdentifier cellId;
  DateCellDataPersistence({
    required this.cellId,
  });

  @override
  Future<Option<FlowyError>> save(CalendarData data) {
    var payload = DateChangesetPB.create()..cellPath = _makeCellPath(cellId);

    final date = (data.date.millisecondsSinceEpoch ~/ 1000).toString();
    payload.date = date;
    payload.isUtc = data.date.isUtc;

    if (data.time != null) {
      payload.time = data.time!;
    }

    return GridEventUpdateDateCell(payload).send().then((result) {
      return result.fold(
        (l) => none(),
        (err) => Some(err),
      );
    });
  }
}

CellPathPB _makeCellPath(GridCellIdentifier cellId) {
  return CellPathPB.create()
    ..viewId = cellId.gridId
    ..fieldId = cellId.fieldId
    ..rowId = cellId.rowId;
}
