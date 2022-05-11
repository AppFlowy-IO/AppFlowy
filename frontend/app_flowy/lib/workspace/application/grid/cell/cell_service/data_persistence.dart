part of 'cell_service.dart';

abstract class _GridCellDataPersistence<D> {
  void save(D data);
}

class CellDataPersistence implements _GridCellDataPersistence<String> {
  final GridCell gridCell;

  CellDataPersistence({
    required this.gridCell,
  });
  final CellService _cellService = CellService();

  @override
  void save(String data) {
    _cellService
        .updateCell(
      gridId: gridCell.gridId,
      fieldId: gridCell.field.id,
      rowId: gridCell.rowId,
      data: data,
    )
        .then((result) {
      result.fold((l) => null, (err) => Log.error(err));
    });
  }
}

class DateCellPersistenceData {
  final DateTime date;
  final String? time;
  DateCellPersistenceData({
    required this.date,
    this.time,
  });
}

class NumberCellDataPersistence implements _GridCellDataPersistence<DateCellPersistenceData> {
  final GridCell gridCell;
  NumberCellDataPersistence({
    required this.gridCell,
  });

  @override
  void save(DateCellPersistenceData data) {
    var payload = DateChangesetPayload.create()..cellIdentifier = _cellIdentifier(gridCell);

    final date = (data.date.millisecondsSinceEpoch ~/ 1000).toString();
    payload.date = date;

    if (data.time != null) {
      payload.time = data.time!;
    }

    GridEventUpdateDateCell(payload).send().then((result) {
      result.fold((l) => null, (err) => Log.error(err));
    });
  }
}

CellIdentifierPayload _cellIdentifier(GridCell gridCell) {
  return CellIdentifierPayload.create()
    ..gridId = gridCell.gridId
    ..fieldId = gridCell.field.id
    ..rowId = gridCell.rowId;
}
