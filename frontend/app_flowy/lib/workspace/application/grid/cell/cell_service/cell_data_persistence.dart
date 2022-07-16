part of 'cell_service.dart';

/// Save the cell data to disk
/// You can extend this class to do custom operations. For example, the DateCellDataPersistence.
abstract class IGridCellDataPersistence<D> {
  Future<Option<FlowyError>> save(D data);
}

class CellDataPersistence implements IGridCellDataPersistence<String> {
  final GridCellIdentifier gridCell;

  CellDataPersistence({
    required this.gridCell,
  });
  final CellService _cellService = CellService();

  @override
  Future<Option<FlowyError>> save(String data) async {
    final fut = _cellService.updateCell(
      gridId: gridCell.gridId,
      fieldId: gridCell.field.id,
      rowId: gridCell.rowId,
      data: data,
    );

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
  const factory CalendarData({required DateTime date, String? time}) = _CalendarData;
}

class DateCellDataPersistence implements IGridCellDataPersistence<CalendarData> {
  final GridCellIdentifier gridCell;
  DateCellDataPersistence({
    required this.gridCell,
  });

  @override
  Future<Option<FlowyError>> save(CalendarData data) {
    var payload = DateChangesetPayload.create()..cellIdentifier = _cellIdentifier(gridCell);

    final date = (data.date.millisecondsSinceEpoch ~/ 1000).toString();
    payload.date = date;

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

CellIdentifierPayload _cellIdentifier(GridCellIdentifier gridCell) {
  return CellIdentifierPayload.create()
    ..gridId = gridCell.gridId
    ..fieldId = gridCell.field.id
    ..rowId = gridCell.rowId;
}
