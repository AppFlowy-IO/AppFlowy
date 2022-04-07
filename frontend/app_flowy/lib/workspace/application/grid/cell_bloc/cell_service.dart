import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';

class CellService {
  CellService();

  Future<Either<void, FlowyError>> updateCell({
    required String gridId,
    required String fieldId,
    required String rowId,
    required String data,
  }) {
    final payload = CellMetaChangeset.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId
      ..data = data;
    return GridEventUpdateCell(payload).send();
  }
}
