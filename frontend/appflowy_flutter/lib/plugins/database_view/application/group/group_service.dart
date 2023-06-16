import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class GroupBackendService {
  final String viewId;
  GroupBackendService(this.viewId);

  Future<Either<Unit, FlowyError>> groupByField({
    required String fieldId,
  }) {
    final payload = GroupByFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    return DatabaseEventSetGroupByField(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateGroup({
    required String groupId,
    String? name,
    bool? visible,
  }) {
    final payload = UpdateGroupPB.create()..groupId = groupId;
    if (name != null) {
      payload.name = name;
    }
    if (visible != null) {
      payload.visible = visible;
    }
    return DatabaseEventUpdateGroup(payload).send();
  }
}
