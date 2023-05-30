import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group_changeset.pb.dart';

typedef GroupUpdateValue = Either<GroupChangesPB, FlowyError>;
typedef GroupByNewFieldValue = Either<List<GroupPB>, FlowyError>;

class DatabaseGroupListener {
  final String viewId;
  PublishNotifier<GroupUpdateValue>? _numOfGroupsNotifier = PublishNotifier();
  PublishNotifier<GroupByNewFieldValue>? _groupByFieldNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  DatabaseGroupListener(this.viewId);

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
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateNumOfGroups:
        result.fold(
          (payload) => _numOfGroupsNotifier?.value =
              left(GroupChangesPB.fromBuffer(payload)),
          (error) => _numOfGroupsNotifier?.value = right(error),
        );
        break;
      case DatabaseNotification.DidGroupByField:
        result.fold(
          (payload) => _groupByFieldNotifier?.value =
              left(GroupChangesPB.fromBuffer(payload).initialGroups),
          (error) => _groupByFieldNotifier?.value = right(error),
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
