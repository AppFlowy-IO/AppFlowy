import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';

class GridService {
  final String gridId;
  GridService({
    required this.gridId,
  });

  Future<Either<GridPB, FlowyError>> loadGrid() async {
    await FolderEventSetLatestView(ViewIdPB(value: gridId)).send();

    final payload = GridIdPB(value: gridId);
    return GridEventGetGrid(payload).send();
  }

  Future<Either<GridRowPB, FlowyError>> createRow(
      {Option<String>? startRowId}) {
    CreateRowPayloadPB payload = CreateRowPayloadPB.create()..gridId = gridId;
    startRowId?.fold(() => null, (id) => payload.startRowId = id);
    return GridEventCreateRow(payload).send();
  }

  Future<Either<RepeatedGridFieldPB, FlowyError>> getFields(
      {required List<GridFieldIdPB> fieldIds}) {
    final payload = QueryFieldPayloadPB.create()
      ..gridId = gridId
      ..fieldIds = RepeatedGridFieldIdPB(items: fieldIds);
    return GridEventGetFields(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeGrid() {
    final request = ViewIdPB(value: gridId);
    return FolderEventCloseView(request).send();
  }
}
