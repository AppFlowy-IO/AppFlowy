import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pb.dart';

typedef UpdateSettingNotifiedValue = Either<DatabaseViewSettingPB, FlowyError>;

class DatabaseSettingListener {
  final String databaseId;
  DatabaseNotificationListener? _listener;
  PublishNotifier<UpdateSettingNotifiedValue>? _updateSettingNotifier =
      PublishNotifier();

  DatabaseSettingListener({required this.databaseId});

  void start({
    required void Function(UpdateSettingNotifiedValue) onSettingUpdated,
  }) {
    _updateSettingNotifier?.addPublishListener(onSettingUpdated);
    _listener =
        DatabaseNotificationListener(objectId: databaseId, handler: _handler);
  }

  void _handler(DatabaseNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case DatabaseNotification.DidUpdateSettings:
        result.fold(
          (payload) => _updateSettingNotifier?.value = left(
            DatabaseViewSettingPB.fromBuffer(payload),
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
