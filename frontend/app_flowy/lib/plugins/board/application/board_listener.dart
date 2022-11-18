import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/group.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/group_changeset.pb.dart';

typedef GroupUpdateValue = Either<GroupViewChangesetPB, FlowyError>;
typedef GroupByNewFieldValue = Either<List<GroupPB>, FlowyError>;

class BoardListener {
  final String viewId;
  PublishNotifier<GroupUpdateValue>? _groupUpdateNotifier = PublishNotifier();
  PublishNotifier<GroupByNewFieldValue>? _groupByNewFieldNotifier =
      PublishNotifier();
  GridNotificationListener? _listener;
  BoardListener(this.viewId);

  void start({
    required void Function(GroupUpdateValue) onBoardChanged,
    required void Function(GroupByNewFieldValue) onGroupByNewField,
  }) {
    _groupUpdateNotifier?.addPublishListener(onBoardChanged);
    _groupByNewFieldNotifier?.addPublishListener(onGroupByNewField);
    _listener = GridNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    GridDartNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridDartNotification.DidUpdateGroupView:
        result.fold(
          (payload) => _groupUpdateNotifier?.value =
              left(GroupViewChangesetPB.fromBuffer(payload)),
          (error) => _groupUpdateNotifier?.value = right(error),
        );
        break;
      case GridDartNotification.DidGroupByNewField:
        result.fold(
          (payload) => _groupByNewFieldNotifier?.value =
              left(GroupViewChangesetPB.fromBuffer(payload).newGroups),
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
