import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/row_entities.pb.dart';

class DatabaseBackendService {
  final String viewId;
  DatabaseBackendService({
    required this.viewId,
  });

  Future<Either<DatabasePB, FlowyError>> openGrid() async {
    await FolderEventSetLatestView(ViewIdPB(value: viewId)).send();

    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetDatabase(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createRow({Option<String>? startRowId}) {
    var payload = CreateRowPayloadPB.create()..viewId = viewId;
    startRowId?.fold(() => null, (id) => payload.startRowId = id);
    return DatabaseEventCreateRow(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createBoardCard(
    String groupId,
    String? startRowId,
  ) {
    CreateBoardCardPayloadPB payload = CreateBoardCardPayloadPB.create()
      ..viewId = viewId
      ..groupId = groupId;

    if (startRowId != null) {
      payload.startRowId = startRowId;
    }

    return DatabaseEventCreateBoardCard(payload).send();
  }

  Future<Either<List<FieldPB>, FlowyError>> getFields(
      {List<FieldIdPB>? fieldIds}) {
    var payload = GetFieldPayloadPB.create()..viewId = viewId;

    if (fieldIds != null) {
      payload.fieldIds = RepeatedFieldIdPB(items: fieldIds);
    }
    return DatabaseEventGetFields(payload).send().then((result) {
      return result.fold((l) => left(l.items), (r) => right(r));
    });
  }

  Future<Either<Unit, FlowyError>> closeGrid() {
    final request = ViewIdPB(value: viewId);
    return FolderEventCloseView(request).send();
  }

  Future<Either<RepeatedGroupPB, FlowyError>> loadGroups() {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetGroup(payload).send();
  }
}
