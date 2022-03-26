import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:dartz/dartz.dart';

class GridService {
  Future<Either<Grid, FlowyError>> openGrid({required String gridId}) async {
    await FolderEventSetLatestView(ViewId(value: gridId)).send();

    final payload = GridId(value: gridId);
    return GridEventGetGridData(payload).send();
  }

  Future<Either<Row, FlowyError>> createRow({required String gridId, Option<String>? startRowId}) {
    CreateRowPayload payload = CreateRowPayload.create()..gridId = gridId;
    startRowId?.fold(() => null, (id) => payload.startRowId = id);
    return GridEventCreateRow(payload).send();
  }

  Future<Either<RepeatedGridBlock, FlowyError>> getGridBlocks(
      {required String gridId, required List<GridBlockOrder> blockOrders}) {
    final payload = QueryGridBlocksPayload.create()
      ..gridId = gridId
      ..blockOrders.addAll(blockOrders);
    return GridEventGetGridBlocks(payload).send();
  }

  Future<Either<RepeatedField, FlowyError>> getFields({required String gridId, required List<FieldOrder> fieldOrders}) {
    final payload = QueryFieldPayload.create()
      ..gridId = gridId
      ..fieldOrders = RepeatedFieldOrder(items: fieldOrders);
    return GridEventGetFields(payload).send();
  }
}
