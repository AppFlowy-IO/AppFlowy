import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

typedef GroupUpdateValue = FlowyResult<GroupChangesPB, FlowyError>;
typedef GroupByNewFieldValue = FlowyResult<List<GroupPB>, FlowyError>;

class DatabaseGroupListener {
  DatabaseGroupListener(this.viewId);

  final String viewId;

  PublishNotifier<GroupUpdateValue>? _numOfGroupsNotifier = PublishNotifier();
  PublishNotifier<GroupByNewFieldValue>? _groupByFieldNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;

  void start({
    required void Function(GroupUpdateValue) onNumOfGroupsChanged,
    required void Function(GroupByNewFieldValue) onGroupByNewField,
  }) {
    _numOfGroupsNotifier?.addPublishListener(onNumOfGroupsChanged);
    _groupByFieldNotifier?.addPublishListener(onGroupByNewField);
    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    DatabaseNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateNumOfGroups:
        result.fold(
          (payload) => _numOfGroupsNotifier?.value =
              FlowyResult.success(GroupChangesPB.fromBuffer(payload)),
          (error) => _numOfGroupsNotifier?.value = FlowyResult.failure(error),
        );
        break;
      case DatabaseNotification.DidGroupByField:
        result.fold(
          (payload) => _groupByFieldNotifier?.value = FlowyResult.success(
            GroupChangesPB.fromBuffer(payload).initialGroups,
          ),
          (error) => _groupByFieldNotifier?.value = FlowyResult.failure(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _numOfGroupsNotifier?.dispose();
    _numOfGroupsNotifier = null;

    _groupByFieldNotifier?.dispose();
    _groupByFieldNotifier = null;
  }
}
