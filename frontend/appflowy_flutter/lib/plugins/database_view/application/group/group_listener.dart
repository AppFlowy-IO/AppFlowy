import 'dart:typed_data';

import 'package:appflowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group_changeset.pb.dart';

typedef GroupUpdateValue = Either<GroupChangesetPB, FlowyError>;
typedef GroupByNewFieldValue = Either<List<GroupPB>, FlowyError>;

class DatabaseGroupListener {
  final String viewId;
  PublishNotifier<GroupUpdateValue>? _numOfGroupsNotifier = PublishNotifier();
  PublishNotifier<GroupByNewFieldValue>? _groupByFieldNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  DatabaseGroupListener(this.viewId);

  void start({
    required final void Function(GroupUpdateValue) onNumOfGroupsChanged,
    required final void Function(GroupByNewFieldValue) onGroupByNewField,
  }) {
    _numOfGroupsNotifier?.addPublishListener(onNumOfGroupsChanged);
    _groupByFieldNotifier?.addPublishListener(onGroupByNewField);
    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    final DatabaseNotification ty,
    final Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateGroups:
        result.fold(
          (final payload) => _numOfGroupsNotifier?.value =
              left(GroupChangesetPB.fromBuffer(payload)),
          (final error) => _numOfGroupsNotifier?.value = right(error),
        );
        break;
      case DatabaseNotification.DidGroupByField:
        result.fold(
          (final payload) => _groupByFieldNotifier?.value =
              left(GroupChangesetPB.fromBuffer(payload).initialGroups),
          (final error) => _groupByFieldNotifier?.value = right(error),
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
