import 'dart:typed_data';

import 'package:appflowy/core/grid_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pb.dart';

typedef UpdateSettingNotifiedValue = Either<DatabaseViewSettingPB, FlowyError>;

class DatabaseSettingListener {
  final String viewId;
  DatabaseNotificationListener? _listener;
  PublishNotifier<UpdateSettingNotifiedValue>? _updateSettingNotifier =
      PublishNotifier();

  DatabaseSettingListener({required this.viewId});

  void start({
    required final void Function(UpdateSettingNotifiedValue) onSettingUpdated,
  }) {
    _updateSettingNotifier?.addPublishListener(onSettingUpdated);
    _listener =
        DatabaseNotificationListener(objectId: viewId, handler: _handler);
  }

  void _handler(final DatabaseNotification ty, final Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case DatabaseNotification.DidUpdateSettings:
        result.fold(
          (final payload) => _updateSettingNotifier?.value = left(
            DatabaseViewSettingPB.fromBuffer(payload),
          ),
          (final error) => _updateSettingNotifier?.value = right(error),
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
