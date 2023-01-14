import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/row_entities.pb.dart';

class GridFFIService {
  final String gridId;
  GridFFIService({
    required this.gridId,
  });

  Future<Either<GridPB, FlowyError>> openGrid() async {
    await FolderEventSetLatestView(ViewIdPB(value: gridId)).send();

    final payload = GridIdPB(value: gridId);
    return GridEventGetGrid(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createRow({Option<String>? startRowId}) {
    var payload = CreateTableRowPayloadPB.create()..gridId = gridId;
    startRowId?.fold(() => null, (id) => payload.startRowId = id);
    return GridEventCreateTableRow(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createBoardCard(
    String groupId,
    String? startRowId,
  ) {
    CreateBoardCardPayloadPB payload = CreateBoardCardPayloadPB.create()
      ..gridId = gridId
      ..groupId = groupId;

    if (startRowId != null) {
      payload.startRowId = startRowId;
    }

    return GridEventCreateBoardCard(payload).send();
  }

  Future<Either<List<FieldPB>, FlowyError>> getFields(
      {List<FieldIdPB>? fieldIds}) {
    var payload = GetFieldPayloadPB.create()..gridId = gridId;

    if (fieldIds != null) {
      payload.fieldIds = RepeatedFieldIdPB(items: fieldIds);
    }
    return GridEventGetFields(payload).send().then((result) {
      return result.fold((l) => left(l.items), (r) => right(r));
    });
  }

  Future<Either<Unit, FlowyError>> closeGrid() {
    final request = ViewIdPB(value: gridId);
    return FolderEventCloseView(request).send();
  }

  Future<Either<RepeatedGroupPB, FlowyError>> loadGroups() {
    final payload = GridIdPB(value: gridId);
    return GridEventGetGroup(payload).send();
  }
}
