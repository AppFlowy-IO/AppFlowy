import 'package:app_flowy/workspace/application/grid/row_service.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';

class CellService {
  final GridCellData context;

  CellService(this.context);

  Future<Either<void, FlowyError>> updateCell({required String data}) {
    final payload = CellMetaChangeset.create()
      ..gridId = context.gridId
      ..fieldId = context.field.id
      ..rowId = context.rowId
      ..data = data;
    return GridEventUpdateCell(payload).send();
  }
}
