import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/board_card.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/group.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';

class GridFFIService {
  final String gridId;
  GridFFIService({
    required this.gridId,
  });

  Future<Either<GridPB, FlowyError>> loadGrid() async {
    await FolderEventSetLatestView(ViewIdPB(value: gridId)).send();

    final payload = GridIdPB(value: gridId);
    return GridEventGetGrid(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createRow({Option<String>? startRowId}) {
    CreateRowPayloadPB payload = CreateRowPayloadPB.create()..gridId = gridId;
    startRowId?.fold(() => null, (id) => payload.startRowId = id);
    return GridEventCreateRow(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createBoardCard(String groupId) {
    CreateBoardCardPayloadPB payload = CreateBoardCardPayloadPB.create()
      ..gridId = gridId
      ..groupId = groupId;
    return GridEventCreateBoardCard(payload).send();
  }

  Future<Either<RepeatedFieldPB, FlowyError>> getFields(
      {required List<FieldIdPB> fieldIds}) {
    final payload = QueryFieldPayloadPB.create()
      ..gridId = gridId
      ..fieldIds = RepeatedFieldIdPB(items: fieldIds);
    return GridEventGetFields(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeGrid() {
    final request = ViewIdPB(value: gridId);
    return FolderEventCloseView(request).send();
  }

  Future<Either<RepeatedGridGroupPB, FlowyError>> loadGroups() {
    final payload = GridIdPB(value: gridId);
    return GridEventGetGroup(payload).send();
  }
}
