import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class GroupBackendService {
  GroupBackendService(this.viewId);

  final String viewId;

  Future<FlowyResult<void, FlowyError>> groupByField({
    required String fieldId,
    required List<int> settingContent,
  }) {
    final payload = GroupByFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..settingContent = settingContent;

    return DatabaseEventSetGroupByField(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> updateGroup({
    required String groupId,
    String? name,
    bool? visible,
  }) {
    final payload = UpdateGroupPB.create()
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

  Future<FlowyResult<void, FlowyError>> renameGroup({
    required String groupId,
    required String name,
  }) {
    final payload = RenameGroupPB.create()
      ..viewId = viewId
      ..groupId = groupId
      ..name = name;

    return DatabaseEventRenameGroup(payload).send();
  }
}
