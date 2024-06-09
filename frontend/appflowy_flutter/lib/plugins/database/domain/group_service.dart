import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class GroupBackendService {
  GroupBackendService(this.viewId);

  final String viewId;

  Future<FlowyResult<void, FlowyError>> groupByField({
    required String fieldId,
  }) {
    final payload = GroupByFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    return DatabaseEventSetGroupByField(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> updateGroup({
    required String groupId,
    required String fieldId,
    String? name,
    bool? visible,
  }) {
    final payload = UpdateGroupPB.create()
      ..fieldId = fieldId
      ..viewId = viewId
      ..groupId = groupId;

    if (name != null) {
      payload.name = name;
    }
    if (visible != null) {
      payload.visible = visible;
    }
    return DatabaseEventUpdateGroup(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> createGroup({
    required String name,
    String groupConfigId = "",
  }) {
    final payload = CreateGroupPayloadPB.create()
      ..viewId = viewId
      ..name = name;

    return DatabaseEventCreateGroup(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> deleteGroup({
    required String groupId,
  }) {
    final payload = DeleteGroupPayloadPB.create()
      ..viewId = viewId
      ..groupId = groupId;

    return DatabaseEventDeleteGroup(payload).send();
  }
}
