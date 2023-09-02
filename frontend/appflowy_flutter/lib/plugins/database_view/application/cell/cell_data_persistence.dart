part of 'cell_service.dart';

/// Save the cell data to disk
/// You can extend this class to do custom operations.
abstract class CellDataPersistence<D> {
  Future<Option<FlowyError>> save(D data);
}

class TextCellDataPersistence implements CellDataPersistence<String> {
  final DatabaseCellContext cellContext;
  final _cellBackendSvc = CellBackendService();

  TextCellDataPersistence({
    required this.cellContext,
  });

  @override
  Future<Option<FlowyError>> save(String data) async {
    final fut = _cellBackendSvc.updateCell(
      cellContext: cellContext,
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
