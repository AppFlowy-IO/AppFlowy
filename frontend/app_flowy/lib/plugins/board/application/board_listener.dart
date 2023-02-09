import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group_changeset.pb.dart';

typedef GroupUpdateValue = Either<GroupChangesetPB, FlowyError>;
typedef GroupByNewFieldValue = Either<List<GroupPB>, FlowyError>;

class BoardListener {
  final String viewId;
  PublishNotifier<GroupUpdateValue>? _groupUpdateNotifier = PublishNotifier();
  PublishNotifier<GroupByNewFieldValue>? _groupByNewFieldNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  BoardListener(this.viewId);

  void start({
    required void Function(GroupUpdateValue) onBoardChanged,
    required void Function(GroupByNewFieldValue) onGroupByNewField,
  }) {
    _groupUpdateNotifier?.addPublishListener(onBoardChanged);
    _groupByNewFieldNotifier?.addPublishListener(onGroupByNewField);
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
      case DatabaseNotification.DidUpdateGroups:
        result.fold(
          (payload) => _groupUpdateNotifier?.value =
              left(GroupChangesetPB.fromBuffer(payload)),
          (error) => _groupUpdateNotifier?.value = right(error),
        );
        break;
      case DatabaseNotification.DidGroupByField:
        result.fold(
          (payload) => _groupByNewFieldNotifier?.value =
              left(GroupChangesetPB.fromBuffer(payload).initialGroups),
          (error) => _groupByNewFieldNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _groupUpdateNotifier?.dispose();
    _groupUpdateNotifier = null;

    _groupByNewFieldNotifier?.dispose();
    _groupByNewFieldNotifier = null;
  }
}
