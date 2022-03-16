import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';

class CellService {
  final CellContext context;

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

class CellContext {
  final String gridId;
  final String rowId;
  final Field field;
  final Cell? cell;

  CellContext({required this.rowId, required this.gridId, required this.field, required this.cell});
}
