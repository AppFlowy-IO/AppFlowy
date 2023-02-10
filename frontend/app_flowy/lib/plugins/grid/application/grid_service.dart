import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/row_entities.pb.dart';

class DatabaseFFIService {
  final String databaseId;
  DatabaseFFIService({
    required this.databaseId,
  });

  Future<Either<DatabasePB, FlowyError>> openGrid() async {
    await FolderEventSetLatestView(ViewIdPB(value: databaseId)).send();

    final payload = DatabaseIdPB(value: databaseId);
    return DatabaseEventGetDatabase(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createRow({Option<String>? startRowId}) {
    var payload = CreateRowPayloadPB.create()..databaseId = databaseId;
    startRowId?.fold(() => null, (id) => payload.startRowId = id);
    return DatabaseEventCreateRow(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createBoardCard(
    String groupId,
    String? startRowId,
  ) {
    CreateBoardCardPayloadPB payload = CreateBoardCardPayloadPB.create()
      ..databaseId = databaseId
      ..groupId = groupId;

    if (startRowId != null) {
      payload.startRowId = startRowId;
    }

    return DatabaseEventCreateBoardCard(payload).send();
  }

  Future<Either<List<FieldPB>, FlowyError>> getFields(
      {List<FieldIdPB>? fieldIds}) {
    var payload = GetFieldPayloadPB.create()..databaseId = databaseId;

    if (fieldIds != null) {
      payload.fieldIds = RepeatedFieldIdPB(items: fieldIds);
    }
    return DatabaseEventGetFields(payload).send().then((result) {
      return result.fold((l) => left(l.items), (r) => right(r));
    });
  }

  Future<Either<Unit, FlowyError>> closeGrid() {
    final request = ViewIdPB(value: databaseId);
    return FolderEventCloseView(request).send();
  }

  Future<Either<RepeatedGroupPB, FlowyError>> loadGroups() {
    final payload = DatabaseIdPB(value: databaseId);
    return DatabaseEventGetGroup(payload).send();
  }
}
