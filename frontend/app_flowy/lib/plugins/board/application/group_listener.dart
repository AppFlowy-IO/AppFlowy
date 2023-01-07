import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/group.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/group_changeset.pb.dart';

typedef UpdateGroupNotifiedValue = Either<GroupRowsNotificationPB, FlowyError>;

class GroupListener {
  final GroupPB group;
  PublishNotifier<UpdateGroupNotifiedValue>? _groupNotifier = PublishNotifier();
  GridNotificationListener? _listener;
  GroupListener(this.group);

  void start({
    required void Function(UpdateGroupNotifiedValue) onGroupChanged,
  }) {
    _groupNotifier?.addPublishListener(onGroupChanged);
    _listener = GridNotificationListener(
      objectId: group.groupId,
      handler: _handler,
    );
  }

  void _handler(
    GridDartNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridDartNotification.DidUpdateGroup:
        result.fold(
          (payload) => _groupNotifier?.value =
              left(GroupRowsNotificationPB.fromBuffer(payload)),
          (error) => _groupNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _groupNotifier?.dispose();
    _groupNotifier = null;
  }
}
