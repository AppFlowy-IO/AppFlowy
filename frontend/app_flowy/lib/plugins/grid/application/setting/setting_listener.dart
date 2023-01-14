import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/dart_notification.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/setting_entities.pb.dart';

typedef UpdateSettingNotifiedValue = Either<GridSettingPB, FlowyError>;

class SettingListener {
  final String gridId;
  GridNotificationListener? _listener;
  PublishNotifier<UpdateSettingNotifiedValue>? _updateSettingNotifier =
      PublishNotifier();

  SettingListener({required this.gridId});

  void start({
    required void Function(UpdateSettingNotifiedValue) onSettingUpdated,
  }) {
    _updateSettingNotifier?.addPublishListener(onSettingUpdated);
    _listener = GridNotificationListener(objectId: gridId, handler: _handler);
  }

  void _handler(GridDartNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridDartNotification.DidUpdateGridSetting:
        result.fold(
          (payload) => _updateSettingNotifier?.value = left(
            GridSettingPB.fromBuffer(payload),
          ),
          (error) => _updateSettingNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _updateSettingNotifier?.dispose();
    _updateSettingNotifier = null;
  }
}
