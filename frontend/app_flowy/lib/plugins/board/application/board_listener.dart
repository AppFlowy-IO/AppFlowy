import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/group_changeset.pb.dart';

typedef UpdateBoardNotifiedValue = Either<GroupViewChangesetPB, FlowyError>;

class BoardListener {
  final String viewId;
  PublishNotifier<UpdateBoardNotifiedValue>? _groupNotifier = PublishNotifier();
  GridNotificationListener? _listener;
  BoardListener(this.viewId);

  void start({
    required void Function(UpdateBoardNotifiedValue) onBoardChanged,
  }) {
    _groupNotifier?.addPublishListener(onBoardChanged);
    _listener = GridNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    GridNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridNotification.DidUpdateGroupView:
        result.fold(
          (payload) => _groupNotifier?.value =
              left(GroupViewChangesetPB.fromBuffer(payload)),
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
