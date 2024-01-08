import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:dartz/dartz.dart';

import 'cell_controller.dart';
import 'cell_service.dart';

/// Save the cell data to disk
/// You can extend this class to do custom operations.
abstract class CellDataPersistence<D> {
  Future<Option<FlowyError>> save({
    required String viewId,
    required CellContext cellContext,
    required D data,
  });
}

class TextCellDataPersistence implements CellDataPersistence<String> {
  TextCellDataPersistence();

  @override
  Future<Option<FlowyError>> save({
    required String viewId,
    required CellContext cellContext,
    required String data,
  }) async {
    final fut = CellBackendService.updateCell(
      viewId: viewId,
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
